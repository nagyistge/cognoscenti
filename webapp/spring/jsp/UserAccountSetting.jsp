<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.NGRole"
%><%@page import="org.socialbiz.cog.License"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.BookInfoRecord"
%><%

    ar.assertLoggedIn("");
    String accountId = ar.reqParam("accountId");
    NGBook  ngb = ar.getCogInstance().getSiteByIdOrFail(accountId);
    String pageAddress = ar.getResourceURL(ngb,"personal.htm");
    String[] names = ngb.getSiteNames();
    JSONObject siteInfo = new JSONObject();

%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.siteInfo = <%siteInfo.write(out,2,4);%>;

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

});

</script>

<div ng-app="myApp" ng-controller="myCtrl">


    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Site Settings
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="">Do Nothing</a></li>
            </ul>
          </span>

        </div>
    </div>


    <div class="generalContent">
        <form action="changeAccountName.form" method="post">
            <table>
                <tr>
                    <td class="gridTableColummHeader_2">Site Name:</td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="hidden" name="p" value="<%ar.writeHtml(accountId);%>">
                        <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                        <input type="hidden" name="go" value="<%ar.writeHtml(ar.getCompleteURL());%>">
                        <input type="text" class="form-control" name="newName"
                            value="<%ar.writeHtml(ngb.getFullName());%>">
                    </td>
                </tr>
                <tr><td height="5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit" value='<fmt:message key="nugen.generatInfo.Button.Caption.Admin.ChangePage"/>'
                            name="action" class="btn btn-primary">

                    </td>
                </tr>
                <tr><td height="10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2" valign="top"><fmt:message key="nugen.generatInfo.Admin.Page.PreviousDelete"/></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="hidden" name="p" value="<%ar.writeHtml(ngb.getFullName());%>">
                        <input type="hidden" name="go" value="<%ar.writeHtml(pageAddress);%>">
                        <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC" />
                        <%
                        for (int i = 1; i < names.length; i++) {
                            String delLink = ar.retPath+"t/"+ngb.getKey()
                            + "/$/deletePreviousAccountName.htm?action=delName&p="
                            + URLEncoder.encode(ngb.getFullName(), "UTF-8")
                            + "&oldName="
                            + URLEncoder.encode(names[i], "UTF-8");
                            //out.write("<td>");
                            ar.writeHtml(names[i]);
                            out.write(" &nbsp; <a href=\"");
                            ar.writeHtml(delLink);
                            out.write("\" title=\"delete this name from project\"><img src=\"");
                            out.write(ar.retPath);
                            out.write("assets/iconDelete.gif\"></a><br />\n");
                        }
                        %>
                    </td>
                </tr>
            </table>
        </form>
    </div>
    <div style="height:20px;"></div>
    <div class="generalContent">
        <form action="changeAccountDescription.form" method="post">
            <input type="hidden" name="p" value="<%ar.writeHtml(ngb.getFullName());%>">
            <input type="hidden" name="go" value="<%ar.writeHtml(pageAddress);%>">
            <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC" />
            <table>
                <tr><td height="5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2" valign="top">Site Description:</td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="hidden" name="p" value="<%ar.writeHtml(accountId);%>">
                        <input type="hidden" name="encodingGuard" value="%E6%9D%B1%E4%BA%AC"/>
                        <textarea  name="desc" id="desc" class="form-control" rows="4"><%ar.writeHtml(ngb.getDescription());%></textarea>
                    </td>
                </tr>
                <tr><td height="5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit" value="Change Description" name="action" class="btn btn-primary" />
                    </td>
                </tr>
                <tr><td height="30px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">Current Theme:</td>
                    <td style="width:20px;"></td>
                    <td>
                        <select name="theme" id="theme" class="form-control">
                        <%
                        for(String themeName : ngb.getAllThemes(ar.getCogInstance())) {
                            String img=ar.retPath+"theme/"+themeName+"/themeIcon.gif";
                            ar.write("     <option ");
                            if (themeName.equals(ngb.getThemeName())) {
                                 ar.write("selected=\"selected\" ");
                            }
                            ar.write(" title=\"");
                            ar.write(img);
                            ar.write("\" value=\"");
                            ar.writeHtml(themeName);
                            ar.write("\">");
                            ar.writeHtml(themeName);
                            ar.write("</option>");
                        }
                        %>
                        </select>
                    </td>
                </tr>
                <tr><td height="5px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2"></td>
                    <td style="width:20px;"></td>
                    <td>
                        <input type="submit" value="Change Theme" name="action" class="btn btn-primary" />
                    </td>
                </tr>
                <tr><td height="10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">Site Key:</td>
                    <td style="width:20px;"></td>
                    <td>
                        <% ar.writeHtml(ngb.getKey()); %>
                    </td>
                </tr>
                <tr><td height="10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader_2">Storage Path:</td>
                    <td style="width:20px;"></td>
                    <td>
                        <%
                        File rf = ngb.getSiteRootFolder();
                        if (rf!=null) {
                            ar.writeHtml(rf.toString());
                        }
                        else {
                            ar.write("<i>none</i>");
                        }
                        %>
                    </td>
                </tr>
                <tr>
                    <td class="gridTableColummHeader_2">Streaming Link:</td>
                    <td style="width:20px;"></td>
                    <td><%
                        License lic = null;
                        for (License test : ngb.getLicenses()) {
                            //just find any one license that is still valid
                            if (ar.nowTime < test.getTimeout()) {
                                lic = test;
                            }
                        }
                        //ok ... since at this time there is no UI for creating licenses
                        //in order to test, we just create a license on the fly here, and
                        //also save the project, which is not exactly proper.
                        //TODO: clean this up
                        if (lic==null) {
                            lic = ngb.createLicense(ar.getBestUserId(), "Owners", ar.nowTime+(1000*60*60*24*365), false);
                            ngb.saveFile(ar, "Created license on the fly for testing purposes");
                        }
                        String link = ar.baseURL + "api/" + ngb.getKey() + "/$/summary.json?lic="+lic.getId();
                        ar.writeHtml(link);
                        %>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>
