<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    ar.assertLoggedIn("Must be logged in to see anything about a meeting");

    String pageId      = ar.reqParam("pageId");
    NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngp);
    NGBook ngb = ngp.getSite();
    UserProfile uProf = ar.getUserProfile();
    String currentUser = uProf.getUniversalId();
    String currentUserName = uProf.getName();

    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngp.findMeeting(meetId);
    JSONObject meetingInfo = mRec.getFullJSON(ar, ngp);
    JSONArray attachmentList = ngp.getJSONAttachments(ar);
    JSONArray goalList = ngp.getJSONGoals();

    JSONArray allPeople = UserManager.getUniqueUsersJSON();

/* PROTOTYPE

    $scope.meeting = {
      "agenda": [
        {
          "actionItems": [
            "BKLQHEHWG@clone-c-of-clone-4@8005",
            "HFCKCQHWG@clone-c-of-clone-4@0353"
          ],
          "desc": "An autocracy vests power in one person or set of persons, an \u201cauto\" that can ignore the rest of the organization and make decisions without consultation. This discourages the development of leadership and creative ideas in the organization. This can also produce bad decisions because other members of the organization are afraid to share negative information. While some associations are democratic, most are autocratic with power vested in a board of directors. Employees and members alike can be ignored. Non-profits, like businesses, are almost exclusively autocratic.",
          "docList": [
            "VKSSSCSRG@sec-inline-xbrl@4841",
            "HGYDQWIWG@clone-c-of-clone-4@9358"
          ],
          "duration": 14,
          "id": "1695",
          "notes": "Randy says he is interested in this topic.\n\nan another as well\n\nBy contrast, democracy vests power in the \u201cdemos,\u201d in the population, without respect to their understanding of the issues or of each other. In a democracy, the majority of the \u201cdemos\u201d can ignore the minority of the \u201cdemos\u201d when they make decisions. This inevitably produces factions and conflict rather than harmony. It encourages people to build alliances, trade favors, and think politically rather than achieving the aims of  the organization.",
          "position": 1,
          "subject": "Approve Advertising Plan"
        },
        {
          "actionItems": [],
          "desc": "Many new organizational systems make use of, indeed require, higher levels of shared information and multi-side communications than traditional command and control systems. We are using Sociocracy as our starting example of such a system and test case but we do so with the awareness that there are many other \"hi-com\" systems that are likely to have similar and overlapping needs for communications support.",
          "docList": [],
          "duration": 5,
          "id": "2695",
          "notes": "",
          "position": 2,
          "subject": "Location of New Offices"
        },
        {
          "actionItems": ["XQCTXVJWG@clone-c-of-clone-4@0938"],
          "desc": "do you like electric or gasoline?",
          "docList": [],
          "duration": 5,
          "id": "3695",
          "notes": "",
          "position": 3,
          "subject": "Discuss New Car Model"
        },
        {
          "actionItems": [],
          "desc": "A sociocratic organization is governed by \"circles,\" semi-autonomous policy decision-making groups that correspond to working groups, whether they are departments, teams, or local neighborhood associations. Each circle has its own aim and steers its own work by performing all the functions of  leading, doing, and measuring on its own operations. Together the three steering functions establish a feedback loop, making the circle self-correcting, or self-regulating.\n\nIn circle meetings, each person is equivalent and has the power to consent or object to proposed actions that affect their responsibility in the organization.\n\nOn a daily basis, activities are directed by a leader without discussion or reevaluation of decisions. This produces efficiency and forward movement. If there is disagreement, the leader makes the decision in the moment. the issue is discussed in the next circle meeting, and a policy is established to govern such decisions in the future.",
          "docList": [],
          "duration": 5,
          "id": "0675",
          "notes": "",
          "position": 4,
          "subject": "Discuss Budget"
        }
      ],
      "duration": 60,
      "id": "0695",
      "meetingInfo": "Please join us in Austin for [CHEST 2014|http://2014.chestmeeting.chestnet.org/Meeting-Information], your connection to education opportunities that will help optimize the clinical decisions you make. The cutting-edge sessions and community of innovative problem-solvers in attendance will inspire and energize you. CHEST 2014 takes place at:\n\n* Austin Convention Center\n* 500 E Cesar Chavez Street\n* Austin, Texas 78701",
      "name": "Status Meeting",
      "startTime": 1434137400000,
      "state": 1
    };



    $scope.attachmentList = [
      {
        "attType": "FILE",
        "deleted": false,
        "description": "Original Contract from the SEC to Fujitsu",
        "id": "1002",
        "labelMap": {},
        "modifiedtime": 1391185776500,
        "modifieduser": "cparker@us.fujitsu.com",
        "name": "Contract 13-C-0113-Fujitsu.pdf",
        "public": false,
        "size": 409333,
        "universalid": "CSWSLRBRG@sec-inline-xbrl@0056",
        "upstream": true
      },

*/


%>

<link href="<%=ar.retPath%>assets/font-awesome/css/font-awesome.min.css" rel="stylesheet" />

<link href="<%=ar.retPath%>jscript/textAngular.css" rel="stylesheet" />
<script src="<%=ar.retPath%>jscript/textAngular-rangy.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular-sanitize.min.js"></script>
<script src="<%=ar.retPath%>jscript/textAngular.min.js"></script>

<style>
    .meeting-icon {
       cursor:pointer;
       color:LightSteelBlue;
    }

    .comment-outer {
        border: 1px solid lightgrey;
        border-radius:8px;
        padding:5px;
        margin-top:15px;
        background-color:#EEE;
    }
    .comment-inner {
        border: 1px solid lightgrey;
        border-radius:6px;
        padding:5px;
        background-color:white;
    }
</style>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap', 'textAngular']);
app.controller('myCtrl', function($scope, $http) {
    $scope.meeting = <%meetingInfo.write(out,2,4);%>;
    $scope.goalList = <%goalList.write(out,2,4);%>;
    $scope.attachmentList = <%attachmentList.write(out,2,4);%>;
    $scope.allPeople = <%allPeople.write(out,2,4);%>;
    $scope.newAssignee = "";
    $scope.newGoal = {};
    $scope.newPerson = "";
    $scope.myUserId = "<% ar.writeJS(ar.getBestUserId()); %>";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };


    $scope.showItemMap = {};
    $scope.nowEditing = "nothing";
    $scope.editComment = false;
    $scope.sortItems = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        });
        return $scope.meeting.agenda;
    };

    $scope.showAll = function() {
        $scope.meeting.agenda.map( function(item) {
            $scope.showItemMap[item.id] = true;
        });
    }
    $scope.showAll();

    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };
    $scope.datePickOpen = false;
    $scope.openDatePicker = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen = true;
    };

    $scope.sortItems = function() {
        $scope.meeting.agenda.sort( function(a, b){
            return a.position - b.position;
        } );
        var runTime = $scope.meetingTime;
        var runDur = 0;
        for (var i=0; i<$scope.meeting.agenda.length; i++) {
            var item = $scope.meeting.agenda[i];
            item.position = i+1;
            item.schedule = runTime;
            runDur = runDur + item.duration;
            runTime = new Date( runTime.getTime() + (item.duration*60000) );
        }
        $scope.meeting.endTime = runTime;
        $scope.meeting.totalDuration = runDur;
        return $scope.meeting.agenda;
    };
    $scope.extractDateParts = function() {
        $scope.meetingTime = new Date($scope.meeting.startTime);
        $scope.meetingHour = $scope.meetingTime.getHours();
        $scope.meetingMinutes = $scope.meetingTime.getMinutes();
        $scope.sortItems();
    };
    $scope.extractDateParts();

    $scope.itemDocs = function(item) {
        var res = [];
        for (var j=0; j<item.docList.length; j++) {
            var docId = item.docList[j];
            for(var i=0; i<$scope.attachmentList.length; i++) {
                var oneDoc = $scope.attachmentList[i];
                if (oneDoc.universalid == docId) {
                    res.push(oneDoc);
                }
            }
        }
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
    $scope.itemGoals = function(item) {
        var res = [];
        for (var j=0; j<item.actionItems.length; j++) {
            var aiId = item.actionItems[j];
            for(var i=0; i<$scope.goalList.length; i++) {
                var oneGoal = $scope.goalList[i];
                if (oneGoal.universalid == aiId) {
                    res.push(oneGoal);
                }
            }
        }
        return res;
    }



    $scope.stateName = function() {
        if ($scope.meeting.state<=1) {
            return "Planning";
        }
        if ($scope.meeting.state==2) {
            return "Running";
        }
        return "Completed";
    };

    $scope.meetingStateStyle = function(val) {
        if (val<=1) {
            return "background-color:white";
        }
        if (val==2) {
            return "background-color:lightgreen";
        }
        if (val>2) {
            return "background-color:gray";
        }
        return "Unknown";
    }

    $scope.changeMeetingState = function(newState) {
        $scope.meeting.state = newState;
        $scope.saveMeeting();
    };
    $scope.saveMeeting = function() {
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meeting.startTime = $scope.meetingTime.getTime();

        $scope.sortItems();
        $scope.putGetMeetingInfo($scope.meeting);
    };
    $scope.savePartialMeeting = function(fieldList) {
        $scope.meetingTime.setHours($scope.meetingHour);
        $scope.meetingTime.setMinutes($scope.meetingMinutes);
        $scope.meeting.startTime = $scope.meetingTime.getTime();

        var saveRecord = {};
        for (var j=0; j<fieldList.length; j++) {
            saveRecord[fieldList[j]] = $scope.meeting[fieldList[j]];
        }
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.saveAgendaItem = function(agendaItem) {
        agendaItem.clearLock = "true";
        var saveRecord = {};
        saveRecord.agenda = [agendaItem];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.revertAllEdits = function() {
        var saveRecord = {};
        $scope.putGetMeetingInfo(saveRecord);
        $scope.stopEditing();
    };
    $scope.putGetMeetingInfo = function(readyToSave) {
        var postURL = "meetingUpdate.json?id="+$scope.meeting.id;
        if (readyToSave.id=="~new~") {
            postURL = "agendaAdd.json?id="+$scope.meeting.id;
        }
        var postdata = angular.toJson(readyToSave);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.extractDateParts();
            $scope.editHead=false;
            $scope.editDesc=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.createAgendaItemImmediate = function() {
        var newAgenda = {subject: "New Agenda Item",duration: 10,position:9999,docList:[], actionItems:[]};

        postURL = "agendaAdd.json?id="+$scope.meeting.id;
        var postdata = angular.toJson(newAgenda);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting.agenda.push(data);
            $scope.nowEditing=data.id+"x2";
            $scope.editHead=false;
            $scope.editDesc=false;
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };
    $scope.createAgendaItem = function() {
        var newAgenda = {
            subject: "New Agenda Item",
            id:"~new~",
            duration:10,
            position:$scope.meeting.agenda.length+1,
            docList:[],
            presenters:[],
            actionItems:[]
        };
        $scope.meeting.agenda.push(newAgenda);
        $scope.nowEditing=newAgenda.id+"x2";
    };

    $scope.addAttachment = function(item, doc) {
        for (var i=0; i<item.docList.length; i++) {
            if (doc.universalid == item.docList[i]) {
                alert("Document already attached: "+doc.name);
                return;
            }
        }
        item.docList.push(doc.universalid);
        $scope.saveAgendaItem(item);
        $scope.newAttachment = "";
    }
    $scope.removeAttachment = function(item, doc) {
        var newVal = [];
        for( var i=0; i<item.docList.length; i++) {
            if (item.docList[i]!=doc.universalid) {
                newVal.push(item.docList[i]);
            }
        }
        item.docList = newVal;
        $scope.saveAgendaItem(item);
    }

    $scope.getPeople = function(viewValue) {
        var newVal = [];
        for( var i=0; i<$scope.allPeople.length; i++) {
            var onePeople = $scope.allPeople[i];
            if (onePeople.uid.indexOf(viewValue)>=0) {
                newVal.push(onePeople);
            }
            else if (onePeople.name.indexOf(viewValue)>=0) {
                newVal.push(onePeople);
            }
        }
        return newVal;
    }

    $scope.createActionItem = function(item) {
        var postURL = "createActionItem.json?id="+$scope.meeting.id+"&aid="+item.id;
        var newSynop = $scope.newGoal.synopsis;
        if (newSynop == null || newSynop.length==0) {
            alert("must enter a description of the action item");
            return;
        }
        for(var i=0; i<$scope.goalList.length; i++) {
            var oneItem = $scope.goalList[i];
            if (oneItem.synposis == newSynop) {
                item.actionItems.push(oneItem.universalid);
                $scope.newGoal = {};
                $scope.calcAllActions();
                return;
            }
        }
        $scope.newGoal.state=2;
        $scope.newGoal.assignTo = [];
        var player = $scope.newGoal.assignee;
        if (typeof player == "string") {
            var pos = player.lastIndexOf(" ");
            var name = player.substring(0,pos).trim();
            var uid = player.substring(pos).trim();
            player = {name: name, uid: uid};
        }

        $scope.newGoal.assignTo.push(player);

        var postdata = angular.toJson($scope.newGoal);
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.goalList.push(data);
            item.actionItems.push(data.universalid);
            $scope.newGoal = {};
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
        $scope.stopEditing();
    };

    $scope.toggleEditor = function(whichone, itemid) {
        var combo = itemid+"x"+whichone;
        if ($scope.nowEditing == combo) {
            $scope.nowEditing = "nothing";
            return;
        }
        if ($scope.nowEditing == "nothing") {
            $scope.nowEditing = combo;
            return;
        }
    }
    $scope.stopEditing =  function() {
        $scope.nowEditing = "nothing";
    }

    $scope.isEditing = function(whichone, itemid) {
        var combo = itemid+"x"+whichone;
        return $scope.nowEditing == combo;
    }

    $scope.refresh = function() {
        if ($scope.meeting.state!=2) {
            $scope.refreshStatus = "No refresh because meeting is not being run";
            return;  //don't set of refresh unless in run mode
        }
        window.setTimeout( function() {$scope.refresh()}, 5000);
        if ($scope.nowEditing != "nothing") {
            $scope.refreshStatus = "No refresh because currently editing";
            return;   //don't refresh when editing
        }
        if ($scope.editComment) {
            $scope.refreshStatus = "No refresh because currently making a comment";
            return;   //don't refresh when editing
        }
        $scope.refreshStatus = "Refreshing";
        $scope.putGetMeetingInfo( {} );
        $scope.refreshCount++;
    }
    $scope.refreshCount = 0;
    $scope.refresh();

    $scope.getPresenters = function(item) {
        var res = [];
        $scope.allPeople.map( function(a) {
            item.presenters.map( function(b) {
                if (b == a.uid) {
                    res.push(a);
                }
            });
        });
        return res;
    }
    $scope.addPresenter = function(item, person) {
        console.log("entering addPresenter");
        var notPresent = true;
        console.log("Person is "+person.name);
        item.presenters.map( function(b) {
            if (b == person.uid) {
                notPresent = false;
            }
        });
        if (notPresent) {
            item.presenters.push(person.uid);
        }
    }
    $scope.removePresenter = function(item, person) {
        var newSet = [];
        item.presenters.map( function(b) {
            if (b != person.uid) {
                newSet.push(b);
            }
        });
        item.presenters = newSet;
    }

    $scope.findPersonName = function(email) {
        var person = {name: email};
        $scope.allPeople.map( function(item) {
            if (item.uid == email) {
                person = item;
            }
        });
        return person.name;
    }

    $scope.createMinutes = function() {
        var postURL = "createMinutes.json?id="+$scope.meeting.id;
        var postdata = angular.toJson("");
        $scope.showError=false;
        $http.post(postURL ,postdata)
        .success( function(data) {
            $scope.meeting = data;
            $scope.showInput=false;
            $scope.extractDateParts();
        })
        .error( function(data, status, headers, config) {
            $scope.reportError(data);
        });
    };

    $scope.startEdit = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.setLock = true;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.nowEditing=item.id+"x1"
    }
    $scope.cancelEdit = function(item) {
        var rec = {};
        rec.id = item.id;
        rec.clearLock = true;
        var saveRecord = {};
        saveRecord.agenda = [rec];
        $scope.putGetMeetingInfo(saveRecord);
        $scope.nowEditing="nothing";
    }
    $scope.startNewComment = function(item, isPoll) {
        item.newComment = {};
        item.newComment.choices = ["Consent", "Object"];
        item.newComment.html="";
        item.newComment.poll=isPoll;
        $scope.toggleEditor(8,item.id)
    }
    $scope.createNewComment = function(item) {
        $scope.saveAgendaItem(item);
    }

    $scope.getMyResponse = function(cmt) {
        cmt.choices = ["Consent", "Object"]
        var selected = [];
        if (cmt.user=="<%ar.writeJS(currentUser);%>") {
            return selected;
        }
        cmt.responses.map( function(item) {
            if (item.user=="<%ar.writeJS(currentUser);%>") {
                selected.push(item);
            }
        });
        if (selected.length == 0) {
            var newResponse = {};
            newResponse.user = "<%ar.writeJS(currentUser);%>";
            cmt.responses.push(newResponse);
            selected.push(newResponse);
        }
        return selected;
    }

    $scope.startResponse = function(cmt, pickedChoice) {
        $scope.toggleEditor(9,cmt.time);
        var myList = $scope.getMyResponse(cmt);
        if (myList.length>0) {
            myList[0].choice = pickedChoice;
        }
    }

    $scope.createModifiedProposal = function(item, cmt) {
        item.newComment = {}
        item.newComment.html = cmt.html;
        item.newComment.time = cmt.time + 1;
        item.newComment.poll = true;
        item.newPoll = true;
        $scope.toggleEditor(8,item.id);
    }

});
</script>


<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Meeting: <a href="meetingFull.htm?id={{meeting.id}}">{{meeting.name}}</a>
            @ {{meeting.startTime|date: "h:mma 'on' dd-MMM-yyyy"}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="#" ng-click="createAgendaItem()" >Create Agenda Item</a></li>
              <li role="presentation"><a role="menuitem" tabindex="-1"
                  href="meeting.htm?id={{meeting.id}}" >Arrange Agenda</a></li>
              <li role="presentation"><a role="menuitem"
                  href="sendNote.htm?meet={{meeting.id}}">Send Email about Meeting</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  href="#" ng-click="createMinutes()">Generate Minutes</a></li>
              <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"
                  href="noteZoom{{meeting.minutesLocalId}}.htm">View Minutes</a></li>
              <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"  target="_blank"
                  href="<%=ar.retPath%>t/editNote.htm?pid=<%ar.writeURLData(pageId);%>&nid={{meeting.minutesLocalId}}">Edit Minutes</a></li>
              <li role="presentation" class="divider"></li>
              <li role="presentation"><a role="menuitem"
                  href="meetingList.htm">List All Meetings</a></li>
            </ul>
          </span>

        </div>
    </div>


    <div>
        <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}">
            State: {{stateName()}} <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                  href="#"  ng-click="changeMeetingState(1)">Plan Meeting</a></li>
              <li role="presentation"><a role="menuitem"
                  href="#" ng-click="changeMeetingState(2)">Run Meeting</a></li>
              <li role="presentation"><a role="menuitem"
                  href="#"  ng-click="changeMeetingState(3)">Complete Meeting</a></li>
            </ul>
        </span>
    </div>


    <table>
      <tr>
        <td style="width:100%">
          <div class="leafContent">
            <span style="font-size:150%;font-weight: bold;">
                Meeting: {{meeting.name}} @ {{meeting.startTime|date: "h:mma 'on' dd-MMM-yyyy"}}
            </span>
            <span ng-show="meeting.state<3">
                (
                <i class="fa fa-cogs meeting-icon" ng-click="toggleEditor(5,'0')"></i>
                <i class="fa fa-pencil-square-o meeting-icon" ng-click="toggleEditor(6,'0')"></i>
                )
            </span>
          </div>
           <div class="well leafContent" ng-show="isEditing(5,'0')">
             <table>
                <tr><td style="height:30px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Name:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2"><input ng-model="meeting.name"  class="form-control"></td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Date:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">

                        <input type="text"
                        style="width:150;"
                        class="form-control"
                        datepicker-popup="dd-MMMM-yyyy"
                        ng-model="meetingTime"
                        is-open="datePickOpen"
                        min-date="minDate"
                        datepicker-options="datePickOptions"
                        date-disabled="datePickDisable(date, mode)"
                        ng-required="true"
                        ng-click="openDatePicker($event)"
                        close-text="Close"/>
                        at
                        <select style="width:50;" ng-model="meetingHour" class="form-control" >
                            <option value="0">00</option>
                            <option value="1">01</option>
                            <option value="2">02</option>
                            <option value="3">03</option>
                            <option value="4">04</option>
                            <option value="5">05</option>
                            <option value="6">06</option>
                            <option value="7">07</option>
                            <option value="8">08</option>
                            <option value="9">09</option>
                            <option>10</option>
                            <option>11</option>
                            <option>12</option>
                            <option>13</option>
                            <option>14</option>
                            <option>15</option>
                            <option>16</option>
                            <option>17</option>
                            <option>18</option>
                            <option>19</option>
                            <option>20</option>
                            <option>21</option>
                            <option>22</option>
                            <option>23</option>
                        </select> :
                        <select  style="width:50;" ng-model="meetingMinutes" class="form-control" >
                            <option value="0">00</option>
                            <option>15</option>
                            <option>30</option>
                            <option>45</option>
                        </select>
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader">Duration:</td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <input ng-model="meeting.duration" style="width:60px;"  class="form-control" >
                        Minutes ({{meeting.totalDuration}} currently allocated)
                    </td>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td class="gridTableColummHeader"></td>
                    <td style="width:20px;"></td>
                    <td colspan="2" class="form-inline form-group">
                        <button ng-click="savePartialMeeting(['name','startTime','duration'])" class="btn btn-danger">Save</button>
                        <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
                    </td>
                </tr>


              </table>
           </div>
        </td>
      </tr>
      <tr>
        <td ng-hide="isEditing(6,'0')" style="width:100%">
           <div class="leafContent">
             <div ng-bind-html="meeting.meetingInfo"></div>
           </div>
        </td>
        <td ng-show="isEditing(6,'0')" style="width:100%">
           <div class="well leafContent">
             <div ng-model="meeting.meetingInfo" ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]" text-angular="" class="leafContent"></div>

             <button ng-click="savePartialMeeting(['meetingInfo'])" class="btn btn-danger">Save</button>
             <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
           </div>
        </td>
      </tr>
    </table>

<div ng-repeat="item in meeting.agenda">
    <div style="border: 1px solid lightgrey;border-radius:10px;margin-top:20px;">
    <table >

                          <!--  AGENDA HEADER -->
      <tr>
        <td style="width:100%">
          <div class="leafContent" >
            <span style="font-size:130%;font-weight: bold;" ng-click="showItemMap[item.id]=!showItemMap[item.id]">{{item.position}}. {{item.subject}} &nbsp; </span>
            <span ng-show="showItemMap[item.id] && meeting.state<3">
                ( <i class="fa fa-cogs meeting-icon" ng-click="toggleEditor(2,item.id)"
                    title="Agenda Item Settings"></i>
                <i class="fa fa-pencil-square-o meeting-icon" ng-click="startEdit(item)"
                    title="Agenda Item Description"></i>
                <i class="fa fa-book meeting-icon" ng-click="toggleEditor(3,item.id)"
                    title="Agenda Item Atteched Documents"></i>
                <i class="fa fa-flag meeting-icon" ng-click="toggleEditor(4,item.id)"
                    title="Agenda Item Action Items (Generated Goals)"></i> )
            </span>
            <p><i>{{item.schedule | date: 'hh:mm'}} ({{item.duration}} minutes)</i><span ng-repeat="pres in getPresenters(item)">, {{pres.name}}</span>
            </p>
          </div>
          <div ng-show="isEditing(2,item.id)" class="well">
            <div class="form-inline form-group">
              Name: <input ng-model="item.subject"  class="form-control" style="width:200px;"/>
              Duration: <input ng-model="item.duration"  class="form-control" style="width:50px;"/>
              <button ng-click="saveAgendaItem(item)" class="btn btn-danger">Save</button>
              <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
            </div>
            <div class="form-inline form-group">
              Presenters:
                  <span class="dropdown" ng-repeat="person in getPresenters(item)">
                    <button class="btn btn-sm dropdown-toggle" type="button" id="menu1"
                       data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                       {{person.name}}</button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                       <li role="presentation"><a role="menuitem" title="{{person.name}} {{person.uid}}"
                          ng-click="removePresenter(item, person)">Remove Presenter:<br/>{{person.name}}<br/>{{person.uid}}</a></li>
                    </ul>
                  </span>
                  <span >
                    <button class="btn btn-sm btn-primary" ng-click="showAddPresenter=!showAddPresenter"
                        style="margin:2px;padding: 2px 5px;font-size: 11px;">+</button>
                  </span>
            </div>
            <div class="form-inline form-group" ng-show="showAddPresenter">
                <button ng-click="addPresenter(item,newPerson);showAddPresenter=false" class="form-control btn btn-primary">
                    Add This Presenter</button>
                <input type="text" ng-model="newPerson"  class="form-control"
                    placeholder="Enter Email Address" style="width:350px;"
                    typeahead="person as person.name for person in getPeople($viewValue) | limitTo:12">
            </div>
          </div>
        </td>
      </tr>

                          <!--  AGENDA BODY -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-hide="isEditing(1,item.id) && myUserId == item.lockUser.uid" style="width:100%">
           <button ng-show="item.lockUser.uid && item.lockUser.uid.length>0" class="btn btn-sm" style="background-color:lightyellow;margin-left:20px;">
               {{item.lockUser.name}} is editing.
           </button>
           <div class="leafContent">
             <div ng-bind-html="item.desc"></div>
           </div>
        </td>
        <td ng-show="isEditing(1,item.id) && myUserId == item.lockUser.uid" style="width:100%">
           <div class="well leafContent">
             <div ng-model="item.desc" ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]" text-angular="" class="leafContent"></div>

             <button ng-click="saveAgendaItem(item)" class="btn btn-danger">Save</button>
             <button ng-click="cancelEdit(item)" class="btn btn-danger">Cancel</button>
           </div>
        </td>
      </tr>

                          <!--  AGENDA ATTACHMENTS -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-hide="isEditing(3,item.id)" style="width:100%">
           <div ng-repeat="doc in itemDocs(item)" class="leafContent"  style="margin-left:30px;">
              <a href="docinfo{{doc.id}}.htm">
                  <img src="<%=ar.retPath%>assets/images/iconFile.png"> {{doc.name}}
              </a>
           </div>
        </td>
        <td ng-show="isEditing(3,item.id)" style="width:100%">
           <div class="well">
              <table>
                <tr><td style="height:10px"></td></tr>
                <tr>
                    <td>
                      <div>
                          <span class="dropdown" ng-repeat="doc in itemDocs(item)">
                            <button class="btn dropdown-toggle btn-default" type="button" id="menu1"
                              data-toggle="dropdown" style="margin:2px;padding: 2px 5px;font-size: 11px;">
                            {{doc.name}}</button>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                              <li role="presentation"><a role="menuitem" tabindex="-1"
                                  ng-click="removeAttachment(item, doc)">Remove Document:<br/>{{doc.name}}</a></li>
                            </ul>
                          </span>
                      </div>
                </tr>
                <tr><td style="height:10px"></td></tr>
                <tr >
                    <td class="form-inline form-group">
                        <button ng-click="addAttachment(item, newAttachment)" class="btn btn-primary">Add Document</button>
                        <input type="text" ng-model="newAttachment"  class="form-control" placeholder="Enter Document Name"
                         style="width:350px;" typeahead="att as att.name for att in filterDocs($viewValue) | limitTo:12">
                        <button ng-click="stopEditing()" class="btn btn-primary">Cancel</button>
                    </td>
                </tr>
             </table>
           </div>
           <div style="height:50px"></div>
        </td>
      </tr>

                          <!--  AGENDA Action ITEMS -->
      <tr ng-show="showItemMap[item.id]">
        <td ng-hide="isEditing(4,item.id)" style="width:100%">
           <div ng-repeat="goal in itemGoals(item)" class="leafContent"   style="margin-left:30px;">
              <a href="task{{goal.id}}.htm">
                  <img src="<%=ar.retPath%>assets/goalstate/small{{goal.state}}.gif"> {{goal.synopsis}}
              </a>
           </div>
        </td>
        <td ng-show="isEditing(4,item.id)" style="width:100%">
            <div class="well generalSettings">
                <table>
                   <tr>
                        <td class="gridTableColummHeader">New Goal:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="text" ng-model="newGoal.synopsis" class="form-control" placeholder="What should be done">
                        </td>
                   </tr>
                   <tr><td style="height:10px"></td></tr>
                   <tr>
                        <td class="gridTableColummHeader">Assignee:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <input type="text" ng-model="newGoal.assignee" class="form-control" placeholder="Who should do it"
                               typeahead="person as person.name for person in getPeople($viewValue) | limitTo:12">
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader">Description:</td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <textarea type="text" ng-model="newGoal.description" class="form-control"
                                style="width:450px;height:100px" placeholder="Details"></textarea>
                        </td>
                    </tr>
                    <tr><td style="height:10px"></td></tr>
                    <tr>
                        <td class="gridTableColummHeader"></td>
                        <td style="width:20px;"></td>
                        <td colspan="2">
                            <button class="btn btn-primary" ng-click="createActionItem(item)">Create New Action Item</button>
                            <button class="btn btn-primary" ng-click="revertAllEdits()">Cancel</button>
                        </td>
                    </tr>
                </table>
            </div>
        </td>
      </tr>
      </table>
      </div>

                          <!--  AGENDA comments -->
      <table ng-show="showItemMap[item.id]">
      <tr ng-repeat="cmt in item.comments">
           <td style="width:50px;vertical-align:top;padding:15px;">
               <img style="height:35px;width:35px;" src="<%=ar.retPath%>/users/{{cmt.userKey}}.jpg">
           </td>
           <td>
               <div class="leafContent comment-outer">
                   <div style="">
                       <span ng-hide="cmt.poll"><i class="fa fa-comments-o"></i></span>
                       <span ng-show="cmt.poll"><i class="fa fa-star-o"></i></span>
                       &nbsp; {{cmt.time | date}} - <a href="<%=ar.retPath%>v/{{cmt.userKey}}/userSettings.htm"><span class="red">{{cmt.userName}}</span></a>
                       <span ng-click="toggleEditor(7,cmt.time)" ng-show="cmt.user=='<%=uProf.getUniversalId()%>'">- <a href="">EDIT</a></span>
                   </div>
                   <div class="comment-inner"
                        ng-hide="isEditing(7,cmt.time)">
                     <div ng-bind-html="cmt.html"></div>
                   </div>

                    <div class="well leafContent" style="width:100%" ng-show="isEditing(7,cmt.time)">
                      <div ng-model="cmt.html"
                          ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                          text-angular="" class="" style="width:100%;"></div>

                      <button ng-click="saveAgendaItem(item)" class="btn btn-danger">Save Changes</button>
                      <button ng-click="revertAllEdits()" class="btn btn-danger">Cancel</button>
                      &nbsp;
                      <input type="checkbox" ng-model="cmt.poll"> Proposal</button>
                    </div>

                   <table style="min-width:500px;" ng-show="cmt.poll && !isEditing(9,cmt.time)">
                   <tr ng-repeat="resp in cmt.responses">
                       <td style="padding:5px;max-width:100px;">
                           <b>{{resp.choice}}</b><br/>
                           {{resp.userName}}
                       </td>
                       <td style="padding:5px;">
                          <div ng-bind-html="resp.html"></div>
                       </td>
                   </tr>
                   </table>

                   <div ng-show="cmt.poll && cmt.user=='<%ar.writeJS(currentUser);%>'">
                       <button class="btn btn-default" ng-click="cmt.poll=false;saveAgendaItem(item)">Close Response Period</button>
                       <button class="btn btn-default" ng-click="createModifiedProposal(item,cmt)">Make Modified Proposal</button>
                   </div>
                   <div ng-show="cmt.poll && !isEditing(9,cmt.time) && cmt.user!='<%ar.writeJS(currentUser);%>'">
                       Respond: <span ng-repeat="choice in cmt.choices">&nbsp;
                           <button class="btn btn-primary" ng-click="startResponse(cmt, choice)">
                               {{choice}}
                           </button>
                       </span>&nbsp;
                       <button class="btn btn-default" ng-click="createModifiedProposal(item,cmt)">Make Modified Proposal</button>
                   </div>
                   <div ng-show="cmt.poll && isEditing(9,cmt.time) && cmt.user!='<%ar.writeJS(currentUser);%>'">
                       <h2>Your Response: <%ar.writeHtml(currentUserName);%></h2>
                       <div ng-repeat="myResp in getMyResponse(cmt)">
                          <div class="form-inline form-group">
                              Choice:  <select class="form-control" ng-model="myResp.choice" ng-options="onch as onch for onch in cmt.choices"></select>
                          </div>
                          <div ng-model="myResp.html"
                              ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                              text-angular="" class="" style="width:100%;"></div>
                       </div>
                      <button ng-click="saveAgendaItem(item);stopEditing()" class="btn btn-danger">Save Response</button>
                      <button ng-click="stopEditing()" class="btn btn-danger">Cancel</button>
                   </div>
               </div>
           </td>
      </tr>
      <tr>
        <td></td>
        <td>
        <div ng-hide="isEditing(8,item.id)" style="margin:20px;">
            <button ng-click="startNewComment(item, false)" class="btn btn-default">
                Create New <i class="fa fa-comments-o"></i> Comment</button>
            <button ng-click="startNewComment(item, true)" class="btn btn-default">
                Create New <i class="fa fa-star-o"></i> Proposal</button>
        </div>
        <div ng-show="isEditing(8,item.id)">
            <div class="well leafContent" style="width:100%">
              <div ng-model="item.newComment.html"
                  ta-toolbar="[['h1','h2','h3','p','ul','indent','outdent'],['bold','italics','clear','insertLink'],['undo','redo']]"
                  text-angular="" class="" style="width:100%;"></div>

              <button ng-click="createNewComment(item)" class="btn btn-danger" ng-hide="item.newComment.poll">
                  Create <i class="fa fa-comments-o"></i> Comment</button>
              <button ng-click="createNewComment(item)" class="btn btn-danger" ng-show="item.newComment.poll">
                  Create <i class="fa fa-star-o"></i> Proposal</button>
              <button ng-click="toggleEditor(8,item.id)" class="btn btn-danger">Cancel</button>
              &nbsp;
              <input type="checkbox" ng-model="item.newComment.poll"> Proposal</button>
            </div>
        </div>
        </td>
      </tr>
    </table>
    </div>

    <hr/>
    <div style="margin:20px;">
        <button ng-click="createAgendaItem()" class="btn">Create New Agenda Item</button>
    </div>


    Refreshed {{refreshCount}} times.   {{refreshStatus}}

</div>

