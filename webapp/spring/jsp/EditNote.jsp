<%@page import="org.socialbiz.cog.AuthRequest"
%><%@page import="java.io.StringWriter"
%><%@page import="org.socialbiz.cog.AuthDummy"
%><%@ include file="/spring/jsp/include.jsp"
%><%@ include file="functions.jsp"
%><%

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngp.getSite();
    String nid          = ar.defParam("nid", null);
    JSONObject noteInfo = null;
    boolean isCreate = (nid==null);
    if (!isCreate) {
        NoteRecord note = ngp.getNote(nid);
        noteInfo = note.getJSONWithHtml(ar);
    }
    else {
        noteInfo = new JSONObject();
        //this is a signal to create a note
        noteInfo.put("id", "~new~");
        String isPublic = ar.defParam("public", "false");
        noteInfo.put("public", "true".equals(isPublic));
        noteInfo.put("labelMap", new JSONObject());
        noteInfo.put("docList", new JSONArray());
    }

    JSONArray allLabels = ngp.getJSONLabels();

    JSONArray attachmentList = ngp.getJSONAttachments(ar);


/* NOTE PROTOTYPE

    $scope.noteInfo = {
      "comments": [{
        "content": "here is a comment",
        "time": 1435092319582,
        "user": "kswenson@us.fujitsu.com"
      }],
      "deleted": false,
      "docList": [
        "MAPZIUHWG@test-for-john@6058",
        "MAPZIUHWG@test-for-john@9059"
      ],
      "draft": false,
      "html": "<p>\nHere is an example #tagsAreGood\n<\/p>\n<p>\nAnother is that #peopleAreUseful\n<\/p>\n<p>\nok, got enough?\n<\/p>\n<p>\nxxxxx\n<\/p>\n",
      "id": "7649",
      "labelMap": {},
      "modTime": 1435180202167,
      "modUser": {
        "name": "Keith Swenson",
        "uid": "kswenson@us.fujitsu.com"
      },
      "pin": 0,
      "public": true,
      "subject": "Example Note With Tags",
      "universalid": "PCEDJSNWG@test-for-john@7649"
    };

*/
%>


<link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet" data-semver="4.3.0"
data-require="font-awesome@*" />

<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

<style>
.ta-editor {
    min-height: 300px;
    height: auto;
    overflow: auto;
    font-family: inherit;
    font-size: 100%;
    margin:20px 0;
}
.statictoolbar {
    position: fixed;
    top: 180px;
    z-index: 200;
    left: 50px;
    width: 180px;
}
.staticbutton {
    position: fixed;
    top: 130px;
    z-index: 200;
    left: 50px;
    width: 80px;
}
.staticbutton2 {
    position: fixed;
    top: 130px;
    z-index: 200;
    left: 140px;
    width: 80px;
}
</style>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http) {
    $scope.noteInfo = <%noteInfo.write(out,2,4);%>;
    $scope.isCreate = <%=isCreate%>;
    $scope.allLabels = <%allLabels.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;

    $scope.showInput = false;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        var exception = serverErr.exception;
        $scope.errorMsg = exception.msgs.join(';\n ');
        $scope.errorTrace = exception.stack;
        $scope.showError=true;
        $scope.showTrace = false;
    };

    $scope.saveContents = function(rec) {
        var postURL = "noteHtmlUpdate.json?nid="+$scope.noteInfo.id;
        var postdata = angular.toJson($scope.noteInfo);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.noteInfo = data;
            if ($scope.isCreate) {
                window.location = "editNote.htm?nid="+data.id;
            };
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.hasLabel = function(searchName) {
        return $scope.noteInfo.labelMap[searchName];
    }
    $scope.toggleLabel = function(label) {
        $scope.noteInfo.labelMap[label.name] = !$scope.noteInfo.labelMap[label.name];
    }
    $scope.getDocs = function() {
        var res = [];
        $scope.noteInfo.docList.map( function(docId) {
            $scope.attachmentList.map( function(oneDoc) {
                if (oneDoc.universalid == docId) {
                    res.push(oneDoc);
                }
            });
        });
        return res;
    }
    $scope.filterDocs = function(filter) {
        var res = [];
        for(var i=0; i<$scope.attachmentList.length; i++) {
            var oneDoc = $scope.attachmentList[i];
            if (oneDoc.name.indexOf(filter)>=0) {
                res.push(oneDoc);
            }
            else if (oneDoc.description.indexOf(filter)>=0) {
                res.push(oneDoc);
            }
        }
        return res;
    }
    $scope.addAttachment = function(doc) {
        for (var i=0; i<$scope.noteInfo.docList.length; i++) {
            if (doc.universalid == $scope.noteInfo.docList[i]) {
                alert("Document already attached: "+doc.name);
                return;
            }
        }
        $scope.noteInfo.docList.push(doc.universalid);
        $scope.newAttachment = "";
    }
    $scope.removeAttachment = function(doc) {
        var newVal = [];
        $scope.noteInfo.docList.map( function(docId) {
            if (docId!=doc.universalid) {
                newVal.push(docId);
            }
        });
        $scope.noteInfo.docList = newVal;
    }
});

</script>


<div ng-app="myApp" ng-controller="myCtrl">

    <div id="ErrorPanel" style="border:2px solid red;display=none;background:LightYellow;margin:10px;" ng-show="showError" ng-cloak>
        <div class="generalSettings">
            <table>
                <tr>
                    <td class="gridTableColummHeader">Error:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">{{errorMsg}}</td>
                </tr>
                <tr ng-show="showTrace">
                    <td class="gridTableColummHeader">Trace:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2">{{errorTrace}}</td>
                </tr>
                <tr ng-hide="showTrace">
                    <td class="gridTableColummHeader">Trace:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><button ng-click="showTrace=true">Show The Trace</button></td>
                </tr>
            </table>
        </div>
    </div>


    <table>
    <tr>
        <td style="width:181px;"> <div style="width:181px;"> </div> </td>
        <td style="width:100%;">
            <div class="rightDivContent" style="margin:10px;">
                <button ng-click="saveContents()" class ="btn btn-primary staticbutton" ng-show="isCreate">Create</button>
                <button ng-click="saveContents()" class ="btn btn-primary staticbutton" ng-hide="isCreate">Save</button>
            </div>
            <div style="margin:10px;">
                <input ng-model="noteInfo.subject" class="form-control" style="width:450px;" placeholder="Enter a name for the note here">
            </div>

            <div text-angular-toolbar name="statictoolbar" class="statictoolbar"
                ta-toolbar="[['h1','h2','h3','p'],['ul','indent','outdent'],['bold','italics'],['clear','insertLink'],['undo','redo']]"></div>

            <div ng-model="noteInfo.html"
                ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                ta-target-toolbars='statictoolbar'
                text-angular="" class="leafContent">
            </div>
        </td>
    </tr>

    <!--div ta-bind ng-model="noteInfo.html" class="leafContent" ></div-->

    <tr>
        <td></td>
        <td  valign="top">
           Labels:
          <span class="dropdown" ng-repeat="role in allLabels">
            <button class="btn btn-sm dropdown-toggle labelButton" type="button" id="menu2"
               data-toggle="dropdown" style="background-color:{{role.color}};"
               ng-show="hasLabel(role.name)">{{role.name}}</button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu2">
               <li role="presentation"><a role="menuitem" title="{{add}}"
                  ng-click="toggleLabel(role)">Remove Role:<br/>{{role.name}}</a></li>
            </ul>
          </span>
          <span>
             <span class="dropdown">
               <button class="btn btn-sm btn-primary dropdown-toggle" type="button" id="menu1" data-toggle="dropdown"
               style="padding: 2px 5px;font-size: 11px;"> + </button>
               <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                 <li role="presentation" ng-repeat="rolex in allLabels">
                     <button role="menuitem" tabindex="-1" href="#"  ng-click="toggleLabel(rolex)" class="btn btn-sm labelButton"
                     ng-hide="hasLabel(rolex.name)" style="background-color:{{rolex.color}};">
                         {{rolex.name}}</button></li>
               </ul>
             </span>
          </span>
        </td>
    </tr>


    <tr>
      <td></td>
      <td style="padding-top:20px;">
          Attachments:
          <span class="dropdown" ng-repeat="doc in getDocs()">
            <button class="btn dropdown-toggle" type="button" id="menu1"
              data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
            {{doc.name}}</button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  ng-click="removeAttachment(doc)">Remove Document:<br/>{{doc.name}}</a></li>
            </ul>
          </span>
          <span ng-show="getDocs().length==0 && canUpdate"><i>no documents attached</i></span>
          <button class="btn dropdown-toggle btn-primary" ng-click="showAdd=!showAdd"
              style="margin:2px;padding: 2px 5px;font-size: 11px;" title="Attach a document">
              + </button>
      </td>
    </tr>
    <tr ng-show="showAdd" >
        <td></td>
        <td class="form-inline form-group" style="padding-top:10px;">

            <button ng-click="addAttachment(newAttachment);showAdd=false" class="btn btn-primary">Add Document</button>
            <input type="text" ng-model="newAttachment"  class="form-control" placeholder="Enter Document Name"
             style="width:350px;" typeahead="att as att.name for att in filterDocs($viewValue) | limitTo:12">

    </tr>
    </table>


</div>