<!-- BEGIN slimHeader.jsp -->
<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%!
/*

Parameter used :

    1. pageTitle    : Used to retrieve the page title from request.
    2. userKey      : This is Key of user who is logged in.
    3. pageId       : Id of a Project, used to fetch details of Project (NGPage).
    4. book         : This is key of a site, used here to get details of an Site (NGBook).
    5. viewingSelf  : This parameter is used to check if user is viewing himself/herself or other profile.
    6. headerType   : Used to check the header type whether it is from site, project or user on the basis of
                      it corrosponding tabs are displayed
    7. tabId        : This is tabId when the page ie rendered Tab with this id will be selected.
    8. accountId    : This is key of a site, used here to get details of an Site (NGBook).

*/

    String go="";

%><%


    Cognoscenti cog = ar.getCogInstance();

//pageTitle is a ver strange variable.  I mostly is used to hold the value displayed
//just above the menu.  Usually "Project: My Project"   or "Site: my Site" or "User: Joe User"
//Essentially this depends upon the header type (project, site, or user).
//however the logic is quite convoluted in first detecting what header type it is, and then
//making sure that the right thing is in this value, and then truncating it sometimes.
    String pageTitle = (String)request.getAttribute("pageTitle");

//this indicates a user page
    String userKey = (String)request.getAttribute("userKey");

//this indicates a project page
    String pageId = (String)request.getAttribute("pageId");

//this indicates a site page
    String bookId = (String)request.getAttribute("book");

//apparently this is calculated elsewhere and passed in.
    String viewingSelfStr = (String)request.getAttribute("viewingSelf");

//this is another hint as to the header type
    String headerTypeStr = (String)request.getAttribute("headerType");


    if (headerTypeStr==null) {
        headerTypeStr="user";
    }
    boolean isSiteHeader = false;
    boolean isUserHeader = false;
    boolean isProjectHeader = false;
    if (headerTypeStr.equals("site")) {
        isSiteHeader = true;
        if (bookId==null) {
            throw new Exception("Program Logic Error: need a site id passed to a site style header");
        }
    }
    else if (headerTypeStr.equals("user")) {
        isUserHeader = true;
        //if (userKey==null) {
        //    throw new Exception("Program Logic Error: need a userKey passed to a user style header");
        //}
        //can not test for presence of a user or not .... because unlogged in warning use this
        //probably need a special header type for warnings...like not logged in
    }
    else if (headerTypeStr.equals("project")) {
        isProjectHeader = true;
        if (pageId==null) {
            throw new Exception("Program Logic Error: need a pageId passed to a project style header");
        }
    }
    else {
        throw new Exception("don't understand header type: "+headerTypeStr);
    }

    String tabId = (String)request.getAttribute("tabId");


//What is the difference beween bookid and accountid?  Account, Site, and Book at all the same thing.
//TODO: straighten this out to have only one.
    String accountId = (String)request.getAttribute("accountId");

//We always POST to an address that consumes the data, and then redirects to a display page,
//so the display page (like this one) should never experience a POST request
    ar.assertNotPost();

//TODO: determine what this does.
    String deletedWarning = "";

    NGContainer ngp =null;
    NGBook ngb=null;
    UserProfile userRecord = null;
    if(pageTitle == null && pageId != null){
        ngp  = ar.getCogInstance().getProjectByKeyOrFail(pageId);
    }
    if(isUserHeader && userKey!=null){
        userRecord = UserManager.getUserProfileByKey(userKey);
    }


    if (ngp!=null)
    {
        ar.setPageAccessLevels(ngp);
        pageTitle = ngp.getFullName();
        if(ngp instanceof NGPage) {
            ngb = ((NGPage)ngp).getSite();
        }
        else if(ngp instanceof NGBook) {
            ngb = ((NGBook)ngp);
        }
        if (ngp.isDeleted())
        {
            deletedWarning = "<img src=\""+ar.retPath+"deletedLink.gif\"> (DELETED)";
        }
        else if (ngp.isFrozen())
        {
            deletedWarning = " &#10052; (Frozen)";
        }
    }
    UserProfile uProf = ar.getUserProfile();
    int exposeLevel = 1;
    if (ar.isSuperAdmin()) {
        exposeLevel = 2;
    }


    String currentPageURL = ar.getCompleteURL();
    String encodedLoginMsg = URLEncoder.encode("Can't open form","UTF-8");
    String trncatePageTitle = pageTitle;
    if(pageTitle!=null && pageTitle.length()>60){
        trncatePageTitle=pageTitle.substring(0,60)+"...";
    }

    File themeRoot = cog.getConfig().getFileFromRoot(ar.getThemePath());
    File themeDefault = cog.getConfig().getFileFromRoot("theme/blue/");
    String menuName = "menu4"+headerTypeStr+".json";
    File menuFile = new File(themeRoot, menuName);
    if (!menuFile.exists()) {
        menuFile = new File(themeDefault, menuName);
    }
    if (!menuFile.exists()) {
        throw new Exception("Can not find a menu file for: "+menuFile.toString());
    }



    FileInputStream fis = new FileInputStream(menuFile);
    InputStreamReader isr = new InputStreamReader(fis, "UTF-8");

    %>
<script type="text/javascript">
    menuStruct = <%
        char[] buf = new char[200];
        int amt = isr.read(buf);
        while (amt>0) {
            out.write(buf, 0, amt);
            amt = isr.read(buf);
        }
        isr.close();
    %>;

    function buildMainMenuBar(newStyleTabs){

        for(var j=0;j<newStyleTabs.length ;j++){

            var oneTab = newStyleTabs[j];
            if (oneTab.level><%=exposeLevel%>) {
                continue;
            }

            var subs=oneTab.subs;
            for(var  i=0;i<subs.length ;i++){

                var oneSub = subs[i];
                var mainElement = document.getElementById(oneTab.ref);
                var newli= document.createElement('li');
                var newlink = document.createElement('a');
                var newspan = document.createElement('span');
                newlink.setAttribute('href',oneSub.href);
                newlink.setAttribute('href',oneSub.href);
                newspan.innerHTML=oneSub.name;
                newlink.appendChild(newspan);
                newli.appendChild(newlink);
                mainElement.appendChild(newli);
            }
        }

        var mainElement = document.getElementById("tabs");

        for(var  i=0;i<newStyleTabs.length ;i++){

            var oneTab = newStyleTabs[i];
            if (oneTab.level><%=exposeLevel%>) {
                continue;
            }

            var newli   = document.createElement('li');
            var newlink = document.createElement('a');

            newlink.setAttribute('onclick','updateSpecialTab("'+oneTab.name+'");');
            var newspan = document.createElement('span');

            newlink.setAttribute('href',oneTab.href);
            newlink.setAttribute('rel',oneTab.ref);

            if(i==0){
                newli.className = 'mainNavLink1';
            }

            newspan.innerHTML=oneTab.name;

            newlink.appendChild(newspan);
            newli.appendChild(newlink);
            mainElement.appendChild(newli);

        }

        //TODO: convert to an Angular approach
        ddlevelsmenu.setup("tabs", "topbar");
    }

    function updateSpecialTab(tabName){
        specialTab=tabName;
    }

</script>


<script type="text/javascript">
    var retPath ='<%=ar.retPath%>';
    var headerType = '';
    var book='';
    var pageId = '';
</script>

    <link rel="stylesheet" href="<%=ar.retPath%>css/autocomplete.css" media="screen" type="text/css">
    <script type="text/javascript" src="<%=ar.retPath%>jscript/autocomplete.js"></script>

    <link href="<%=ar.retPath%>css/lightWindow.css" rel="styleSheet" type="text/css" media="screen" />

    <%if(headerTypeStr!=null){ %>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/ddlevelsmenu.js"></script>
    <%} %>


    <%if(headerTypeStr.equalsIgnoreCase("index")){ %>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/prototype.js"></script>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/effects.js"></script>
        <script type="text/javascript" src="<%=ar.retPath%>jscript/lightWindow.js"></script>
    <%} %>



<% if (!headerTypeStr.equals("site")) { %>
    <script>
        var specialTab='<%=tabId%>';
        headerType = "<%=headerTypeStr%>";
        var userKey = "<%=userKey%>";
        var isSuperAdmin = "<%=ar.isSuperAdmin()%>";
        <% if (pageId != null && bookId != null) { %>
          pageId='<%=pageId%>';
          book='<%=bookId%>';
        <% } %>
    </script>

<% } else if(headerTypeStr.equals("site")){ %>
     <script>
        var specialTab='<%=tabId%>';
        headerType = "<%=headerTypeStr%>";
        var userKey = "<%=userKey%>";

        <% if(accountId != null){ %>
        var accountId='<%=accountId %>';
        <% } else if(pageId!=null){ %>
        var accountId='<%=pageId%>';
        <% } %>
     </script>
<% } %>



    <!-- Begin siteMasthead -->
    <div id="siteMasthead">
        <img id="logoInterstage" src="<%=ar.retPath%><%=ar.getThemePath()%>logo.gif" alt="Logo" width="145" height="38" />
        <div id="consoleName">
           <% if(ngb!=null){ %>
           Site: <a href="<%=ar.retPath%>v/<%ar.writeURLData(ngb.getKey());%>/$/accountListProjects.htm"
                     title="View the Site for this page"><%ar.writeHtml(ngb.getFullName());%></a>

           <% } %>
           <br />
           <%
            if(headerTypeStr.equals("user")) {
                if(userRecord!=null){
                    String userName = userRecord.getName();
                    if(userName.length()>60){
                        userName=userName.substring(0,60)+"...";
                    }
                    ar.write("User: <span title=\"");
                    ar.write(userName);
                    ar.write("\">");
                    ar.writeHtml(userName);
                    ar.write("</span>");
                }
            }
            else if(headerTypeStr.equals("site")) {
                if(pageTitle!=null){
                    ar.write("Site: <span title=\"");
                    ar.write(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            else {
                if(pageTitle!=null){
                    ar.write("Project: <span title=\"");
                    ar.write(pageTitle);
                    ar.write("\">");
                    ar.writeHtml(trncatePageTitle);
                    ar.write(deletedWarning);
                    ar.write("</span>");
                }
            }
            %>
        </div>
        <div id="globalLinkArea">
          <ul id="globalLinks">
                <%
                    if(ar.isLoggedIn())
                    {
                        uProf = ar.getUserProfile();
                %>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/watchedProjects.htm"
                                title="Projects for the logged in user">Projects</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userAlerts.htm"
                                title="Updates for the logged in user">Updates</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userActiveTasks.htm"
                                title="Goals for the logged in user">Goals</a></li>
                        <li>|</li>
                        <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/userProfile.htm?active=1"
                                title="Profile for the logged in user">Settings</a></li>
                        <%if(ar.isSuperAdmin()){ %>
                            <li>|</li>
                            <li><a href="<%=ar.retPath%>v/<%ar.writeHtml(uProf.getKey());%>/emailListnerSettings.htm" title="Administration">Administration</a></li>
                        <%} %>
                        <li>|</li>
                        <li class="text last"><a href="<%=ar.retPath%>t/LogoutAction.htm?go=<%ar.writeURLData(currentPageURL);%>">Log Out</a></li>
               <%
                  }
                  else
                  {
               %>
                        <li><a href="<%=ar.retPath%>"
                                title="Initial Introduction Page">Welcome Page</a></li>
                        <li>|</li>
                        <li class="text last"><a href="<%=ar.retPath%>t/EmailLoginForm.htm?go=<%ar.writeURLData(currentPageURL);%>">Log in</a></li>
               <%
                  }
               %>
            </ul>
            </div>
        <%
        if (ar.isLoggedIn())
        {
            UserProfile uProf1 = ar.getUserProfile();
            %>
            <div id="welcomeMessage">
                Welcome, <%uProf1.writeLink(ar); %>
            </div>
            <%
        }
        else
        {
            %>
            <div id="welcomeMessage">
                Not logged in
            </div>
            <%
        }
        %>
    </div>
    <!-- End siteMasthead -->

    <!-- Begin mainNavigation -->
    <div id="mainNavigationLeft">
        <div id="mainNavigationCenter">
            <div id="mainNavigationRight">
            </div>
        </div>
        <div id="mainNavigation">

            <ul id="tabs">

                <div id="zoomOutButton" style="display: none;vertical-align:baseline;" align="right"  >
                    <input type="button" class="btn btn-primary" onclick="zoomOut()" value="<< Back in Project">YES
                </div>
            </ul>
        </div>

        <!--Top Drop Down Menu for project section HTML Starts Here -->
            <ul id="ddsubmenu1" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu2" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu3" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu4" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu5" class="ddsubmenustyle"></ul>
            <ul id="ddsubmenu6" class="ddsubmenustyle"></ul>

    </div>

<script type="text/javascript">
   buildMainMenuBar(menuStruct);
</script>

<!-- End mainNavigation -->

<script>


        function validateDelimEmails(field) {
            var count = 1;
            var result = "";
            var spiltedEmails;
            var value = trimme(field.value);
            if(value != ""){
                if(value.indexOf(";") != -1){
                    spiltedEmails = value.split(";");
                }else if(value.indexOf(",") != -1){
                    spiltedEmails = value.split(",");
                }else if(value.indexOf("\n") != -1){
                    spiltedEmails = value.split("\n");
                }else{
                    value = value+";";
                    spiltedEmails = value.split(";");
                }
                for(var i = 0;i < spiltedEmails.length;i++){
                    var email_id = trimme(spiltedEmails[i]);
                    if(email_id != ""){
                        if(!validateEmail(email_id)){
                            result += "  "+count+".    "+email_id+" \n";
                            count++;
                        }
                    }
                }
            }
            if(result != ""){
                alert("Below is the list of id(s) which does not look like an email. Please enter an email id(s).\n\n"+result);
                field.focus();
                return false;
            }

            return true;
        }
</script>
<!-- END slimHeader.jsp -->
<% out.flush(); %>