<%@page errorPage="/spring/jsp/error.jsp"
%><%@include file="/spring/jsp/include.jsp"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="org.socialbiz.cog.mail.DailyDigest"
%><%@page import="org.socialbiz.cog.GoalRecord"
%><%@page import="org.socialbiz.cog.NGBook"
%><%@page import="org.socialbiz.cog.NGPage"
%><%@page import="org.socialbiz.cog.mail.DailyDigest"
%><%@page import="org.socialbiz.cog.NGPageIndex"
%><%@page import="org.socialbiz.cog.SectionUtil"
%><%@page import="org.socialbiz.cog.SuperAdminLogFile"
%><%@page import="org.socialbiz.cog.UserProfile"
%><%@page import="org.socialbiz.cog.UtilityMethods"
%><%@page import="org.socialbiz.cog.rest.TaskHelper"
%><%@page import="org.springframework.context.ApplicationContext"
%><%@page import="org.w3c.dom.Element"
%><%
    /*

Required Parameters:

    1. userProfile  : This parameter is used to retrieve UserProfile of a user.
    2. messages     : Its used to get ApplicationContext from request.

*/
    UserProfile uProf =(UserProfile)request.getAttribute("userProfile");

    ApplicationContext context = (ApplicationContext)request.getAttribute("messages");

    JSONArray allAlerts = new JSONArray();

    //NEED TO FILL THE ARRAY HERE

    List<NGPageIndex> containers = new ArrayList<NGPageIndex>();
    long lastSendTime = uProf.getNotificationTime();

    //schema migration ... some users will not have this value set.
    //never go back more than twice the notification period.
    //This avoids getting a message with all possible history in it
    long earliestPossible = System.currentTimeMillis()-(uProf.getNotificationPeriod()*2*24*60*60*1000);
    if (lastSendTime<earliestPossible) {
        lastSendTime = earliestPossible;
    }



    List<String> notifications = uProf.getNotificationList();
    if(notifications.size()>0) {
        int count = 0;
        String rowStyleClass = "";
        for (String pageId : notifications) {
            NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageId);
            if (ngpi==null) {
                continue;
                //this can happen if you have something to do in a project that is no longer 
                //in the project.  Right now we ignore them....
            }
            else {
                containers.add(ngpi);
            }
        }
    }
%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Alerts for <%ar.writeJS(uProf.getName());%>");
    $scope.allAlerts = <%allAlerts.write(out,2,4);%>;


    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>


<div class="generalHeading" style="padding-top:35px">Workspace Notifications Since Last Digest
        <%SectionUtil.nicePrintDateAndTime(out, lastSendTime);%></div>
    <p>These notifications, if any, will be included in your next daily digest email.
       Notification period: <%= uProf.getNotificationPeriod() %> days.
    </p>

    <%
     NGPageIndex.clearLocksHeldByThisThread();
     if (containers==null) {
         throw new Exception("How did containers get to be null?");
     }
     DailyDigest.constructDailyDigestEmail(ar,containers,lastSendTime,ar.nowTime);

    out.flush();

%>
</div>
