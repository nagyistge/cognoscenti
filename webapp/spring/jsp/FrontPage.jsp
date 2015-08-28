<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Project and here it is used to retrieve NGPage.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();

    List<HistoryRecord> histRecs = ngp.getAllHistory();
    JSONArray allHistory = new JSONArray();
    for (HistoryRecord hist : histRecs) {
        AddressListEntry ale = new AddressListEntry(hist.getResponsible());
        UserProfile responsible = ale.getUserProfile();
        String imagePath = "assets/photoThumbnail.gif";
        if(responsible!=null) {
            String imgPath = responsible.getImage();
            if (imgPath.length() > 0) {
                imagePath = "users/"+imgPath;
            }
        }
        String objectKey = hist.getContext();
        int contextType = hist.getContextType();
        String key = hist.getCombinedKey();
        String url = "";
        String cType = HistoryRecord.getContextTypeName(contextType);
        String objName = "Unidentified";
        if (contextType == HistoryRecord.CONTEXT_TYPE_PROCESS) {
            url = ar.getResourceURL(ngp, "projectAllTasks.htm");
            objName = "";
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_TASK) {
            url = ar.getResourceURL(ngp, "task"+objectKey+".htm");
            GoalRecord gr = ngp.getGoalOrNull(objectKey);
            if (gr!=null) {
                objName = gr.getSynopsis();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_PERMISSIONS) {
            url = ar.getResourceURL(ngp, "findUser.htm?id=")+URLEncoder.encode(objectKey, "UTF-8");
            objName = objectKey;
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_DOCUMENT) {
            url = ar.getResourceURL(ngp, "docinfo"+objectKey+".htm");
            AttachmentRecord att = ngp.findAttachmentByID(objectKey);
            if (att!=null) {
                objName = att.getDisplayName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_LEAFLET) {
            url = ar.getResourceURL(ngp, "noteZoom"+objectKey+".htm");
            NoteRecord nr = ngp.getNote(objectKey);
            if (nr!=null) {
                objName = nr.getSubject();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_ROLE) {
            url = ar.getResourceURL(ngp, "permission.htm");
            NGRole role = ngp.getRole(objectKey);
            if (role!=null) {
                objName = role.getName();
            }
        }
        else if (contextType == HistoryRecord.CONTEXT_TYPE_MEETING) {
            url = ar.getResourceURL(ngp, "meetingFull.htm?id="+objectKey);
            MeetingRecord meet = ngp.findMeetingOrNull(objectKey);
            if (meet!=null) {
                objName = meet.getName() + " @ " + SectionUtil.getNicePrintDate( meet.getStartTime() );
            }
        }
        JSONObject jObj = new JSONObject();
        jObj.put("timestamp",   hist.getTimeStamp() );
        jObj.put("responsible", ale.getUniversalId() );
        if (responsible!=null) {
            jObj.put("respUrl",     "v/"+responsible.getKey()+"/userSettings.htm" );
        }
        else {
            jObj.put("respUrl",     "findUser.htm?id="+URLEncoder.encode(ale.getUniversalId(),"UTF-8") );
        }
        jObj.put("respName",    ale.getName() );
        jObj.put("imagePath",   imagePath );
        jObj.put("action",      hist.convertEventTypeToString(hist.getEventType()));
        jObj.put("contextUrl",  url );
        jObj.put("contextType", cType );
        jObj.put("context",     hist.getContext() );
        jObj.put("contextName", objName );
        jObj.put("comments",    hist.getComments() );
        allHistory.put(jObj);
    }

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.allHistory = <%allHistory.write(out,2,4);%>;
    $scope.filter = "";

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.processTemplate = function(hist) {
        return hist.template;
    }

    $scope.getHistory = function() {
        if ($scope.filter.length==0) {
            return $scope.allHistory;
        }
        var filter = $scope.filter.toLowerCase();
        var res = [];
        $scope.allHistory.map(  function(hItem) {
            if (hItem.respName.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.contextName.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.comments.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.contextType.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
            else if (hItem.action.toLowerCase().indexOf(filter)>=0) {
                res.push(hItem);
            }
        });
        return res;
    }
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Front Page
        </div>
        <!--div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div-->
    </div>

    <div>
    (Content coming here soon.)
    </div>


</div>