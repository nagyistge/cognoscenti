/*
 * Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog.spring;

import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.socialbiz.cog.AccessControl;
import org.socialbiz.cog.AddressListEntry;
import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.CustomRole;
import org.socialbiz.cog.EmailGenerator;
import org.socialbiz.cog.HistoricActions;
import org.socialbiz.cog.HistoryRecord;
import org.socialbiz.cog.LabelRecord;
import org.socialbiz.cog.NGContainer;
import org.socialbiz.cog.NGLabel;
import org.socialbiz.cog.NGPage;
import org.socialbiz.cog.NGRole;
import org.socialbiz.cog.RoleRequestRecord;
import org.socialbiz.cog.UserManager;
import org.socialbiz.cog.UserProfile;
import org.socialbiz.cog.UtilityMethods;
import org.socialbiz.cog.exception.NGException;
import org.socialbiz.cog.exception.ProgramLogicError;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;
import org.workcast.json.JSONObject;

@Controller
public class ProjectSettingController extends BaseController {

    @RequestMapping(value = "/{siteId}/{pageId}/personal.htm", method = RequestMethod.GET)
    public ModelAndView showPersonalTab(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);

            if (!ar.isLoggedIn()) {
                return showWarningView(ar, "nugen.project.personal.login.msg");
            }

            //signing up as member or other operations require name and email address
            if (needsToSetName(ar)) {
                return new ModelAndView("requiredName");
            }
            if (needsToSetEmail(ar)) {
                return new ModelAndView("requiredEmail");
            }

            ModelAndView modelAndView = new ModelAndView("personal");
            request.setAttribute("visibility_value", "4");

            modelAndView.addObject("page", nGPage);
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Settings");
            return modelAndView;
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.personal.page", new Object[] {
                    pageId, siteId }, ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/personalUpdate.json", method = RequestMethod.POST)
    public void personalUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "Unknown";
        try{
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
            ar.setPageAccessLevels(ngp);
            ar.assertLoggedIn("Must be logged in to set personal settings.");
            JSONObject personalInfo = getPostedObject(ar);
            UserProfile up = ar.getUserProfile();

            op = personalInfo.getString("op");
            if ("SetWatch".equals(op)) {
                up.setWatch(pageId, ar.nowTime);
            }
            else if ("ClearWatch".equals(op)) {
                up.clearWatch(pageId);
            }
            else if ("SetTemplate".equals(op)) {
                up.setProjectAsTemplate(pageId);
            }
            else if ("ClearTemplate".equals(op)) {
                up.removeTemplateRecord(pageId);
            }
            else if ("SetNotify".equals(op)) {
                up.setNotification(pageId, ar.nowTime);
            }
            else if ("ClearNotify".equals(op)) {
                up.clearNotification(pageId);
            }
            else {
                throw new Exception("Unable to understand the operation "+op);
            }

            UserManager.writeUserProfilesToFile();
            JSONObject repo = new JSONObject();
            repo.put("op",  op);
            repo.put("success",  true);
            repo.write(ar.w, 2, 2);
            ar.flush();
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on project "+pageId, ex);
            streamException(ee, ar);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/rolePlayerUpdate.json", method = RequestMethod.POST)
    public void rolePlayerUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "Unknown";
        String roleId= "Unknown";
        try{
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
            ar.setPageAccessLevels(ngp);
            ar.assertLoggedIn("Must be logged in to set personal settings.");
            JSONObject personalInfo = getPostedObject(ar);
            UserProfile up = ar.getUserProfile();

            op = personalInfo.getString("op");
            roleId = personalInfo.getString("roleId");

            NGRole role = ngp.getRoleOrFail(roleId);
            AddressListEntry ale = up.getAddressListEntry();
            RoleRequestRecord rrr = ngp.getRoleRequestRecord(role.getName(),up.getUniversalId());


            if ("Join".equals(op)) {
                if (role.isPlayer(up)) {
                    //don't do anything
                }
                else if (rrr!=null && !rrr.isCompleted()){

                }
                else {
                    rrr = ngp.createRoleRequest(roleId, up.getUniversalId(), ar.nowTime, up.getUniversalId(), "");

                    NGRole adminRole = ngp.getSecondaryRole();
                    NGRole executiveRole = ngp.getSite().getRole("Executives");//getSecondaryRole();

                    boolean isAdmin = adminRole.isPlayer(ale);
                    boolean isExecutive = executiveRole.isPlayer(ale);

                    //Note: if there is no administrator for the project, then ANYONE is allowed to
                    //sign up as ANY role.  Once grabbed, that person is administrator.
                    boolean noAdmin = adminRole.getDirectPlayers().size()==0;

                    if(isAdmin || (isExecutive && "Members".equals(roleId)) || noAdmin ) {
                        rrr.setState("Approved");
                        ngp.addPlayerToRole(roleId,up.getUniversalId());
                    }
                    else{
                        NGWebUtils.sendRoleRequestEmail(ar,rrr,ngp);
                    }
                }
            }
            else if ("Leave".equals(op)) {
                if (role.isPlayer(up)) {
                    role.removePlayer(ale);
                }
                if (rrr!=null && !rrr.isCompleted()) {
                    rrr.setResponseDescription("Cancelled by user");
                    rrr.setCompleted(true);
                }
            }
            else {
                throw new Exception("Unable to understand the operation "+op);
            }

            ngp.saveFile(ar, "Updated role "+roleId);
            JSONObject repo = new JSONObject();
            repo.put("op",  op);
            repo.put("success",  true);
            repo.put("player", role.isPlayer(up));
            RoleRequestRecord rrr2 = ngp.getRoleRequestRecord(role.getName(),up.getUniversalId());
            repo.put("reqPending", (rrr2!=null && !rrr2.isCompleted()));
            repo.write(ar.w, 2, 2);
            ar.flush();
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on role "+roleId+" project  "+pageId, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/roleRequestResolution.json", method = RequestMethod.POST)
    public void roleRequestResolution(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "Unknown";
        String roleName= "Unknown";
        try{
            NGContainer ngc = registerSiteOrProject(ar, siteId, pageId );
            ar.setPageAccessLevels(ngc);
            JSONObject personalInfo = getPostedObject(ar);
            op = personalInfo.getString("op");
            String roleRequestId = personalInfo.getString("rrId");
            RoleRequestRecord rrr = ngc.getRoleRequestRecordById(roleRequestId);
            roleName = rrr.getRoleName();
            boolean canAccess = AccessControl.canAccessRoleRequest(ar, ngc, rrr);

            if (!canAccess) {
                throw new Exception("Unable to access that RoleRequestRecord.  You might need to be logged in.");
            }

            if ("Approve".equals(op)) {
                String requestedBy = rrr.getRequestedBy();
                ngc.addPlayerToRole(roleName,requestedBy);
                rrr.setState("Approved");
                rrr.setCompleted(true);
            }
            else if ("Reject".equals(op)) {
                rrr.setState("Rejected");
                rrr.setCompleted(true);
            }
            else {
                throw new Exception("roleRequestResolution doesn't understand the request for "+op);
            }

            if (ar.isLoggedIn()) {
                ngc.saveFile(ar, "Resolved role "+roleName);
            }
            else {
                ngc.save("Unknown", ar.nowTime, "Resolved role "+roleName, ar.getCogInstance());
            }
            JSONObject repo = new JSONObject();
            repo.put("state", rrr.getState());
            repo.put("completed", rrr.isCompleted());
            repo.write(ar.w, 2, 2);
            ar.flush();
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update the user setting for "+op+" on role "+roleName+" project  "+pageId, ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/permission.htm", method = RequestMethod.GET)
    public ModelAndView showPermissionTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Settings");

            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            List<CustomRole> roles = nGPage.getAllRoles();

            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }

            modelAndView = new ModelAndView("permission");

            //TODO: eliminate these unnecessary parameters
            request.setAttribute("roles", roles);
            modelAndView.addObject("page", nGPage);

            return modelAndView;
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.permission.page", new Object[]{pageId,siteId} , ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/EditRole.htm", method = RequestMethod.GET)
    public ModelAndView editRole(@PathVariable String siteId,@PathVariable String pageId,
            @RequestParam String roleName,
            HttpServletRequest request,
            HttpServletResponse response)
    throws Exception {

        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            NGContainer nGPage  = registerRequiredProject(ar, siteId, pageId);

            List<CustomRole> roles = nGPage.getAllRoles();

            modelAndView = new ModelAndView("EditRole");
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Settings");
            request.setAttribute("roleName", roleName);
            request.setAttribute("roles", roles);
            request.setAttribute("title", " : " + nGPage.getFullName());
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.edit.role.page", new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;

    }
    @RequestMapping(value = "/{siteId}/{pageId}/roleRequest.htm", method = RequestMethod.GET)
    public ModelAndView remindersTab(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);

            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            ar.setPageAccessLevels(nGPage);
            if(!ar.isLoggedIn()){
                request.setAttribute("property_msg_key", "nugen.project.role.request.login.msg");
                modelAndView=new ModelAndView("Warning");
            }else if(!ar.isMember()){
                request.setAttribute("property_msg_key", "nugen.projecthome.rolerequest.memberlogin");
                modelAndView=new ModelAndView("Warning");
            }else{
                modelAndView=new ModelAndView("RoleRequest");
                modelAndView.addObject("page", nGPage);
            }
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.role.request.page", new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;

    }

    //TODO: eliminate this routine
    @RequestMapping(value = "/{siteId}/{pageId}/pageRoleAction.form", method = RequestMethod.POST)
    public ModelAndView pageRoleAction(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        ModelAndView modelAndView = null;
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            if(!ar.isLoggedIn()){
                return showWarningView(ar, "message.loginalert.see.page");
            }
            NGPage ngp = registerRequiredProject(ar, siteId, pageId);

            String r  = ar.reqParam("r");   //role name
            String op = ar.reqParam("op");  //operation: add or remove
            String go = ar.reqParam("go");  //where to go afterwards

            ar.setPageAccessLevels(ngp);
            ar.assertMember("Unable to modify roles.");
            ar.assertNotFrozen(ngp);

            NGRole role = ngp.getRole(r);
            if (role==null)
            {
                if (op.equals("Create Role"))
                {
                    String desc = ar.reqParam("desc");
                    ngp.createRole(r,desc);
                    ngp.saveContent(ar, "create new role "+r);
                    response.sendRedirect(go);
                    return null;
                }
                throw new NGException("nugen.exception.role.not.found", new Object[]{r,ngp.getFullName()});
            }

            boolean isPlayer = role.isExpandedPlayer(ar.getUserProfile(), ngp);
            if (!isPlayer) {
                ar.assertAdmin("You must be a player of the role or project admin to change role '"
                        +r+"'.");
            }

            String id = ar.reqParam("id");  //user being added/removed

            AddressListEntry ale =null;
            if (!op.equals("Add Member")) {
                String parseId = pasreFullname(id );
                ale = AddressListEntry.newEntryFromStorage(parseId);
            }

            int eventType = 0;
            String pageSaveComment = null;

            if (op.equals("Add"))
            {
                if (id.length()<5)
                {
                    throw new NGException("nugen.exception.id.too.small", new Object[]{id});
                }
                eventType = HistoryRecord.EVENT_PLAYER_ADDED;
                pageSaveComment = "added user "+id+" to role "+r;
                role.addPlayerIfNotPresent(ale);
            }
            else if (op.equals("Remove"))
            {
                eventType = HistoryRecord.EVENT_PLAYER_REMOVED;
                pageSaveComment = "removed user "+id+" from role "+r;
                role.removePlayer(ale);
            }
            else if (op.equals("Add Role"))
            {
                eventType = HistoryRecord.EVENT_ROLE_ADDED;
                pageSaveComment = "added new role "+r;
                ale.setRoleRef(true);
                role.addPlayer(ale);
            }
            else if (op.equals("Update Details"))
            {
                eventType = HistoryRecord.EVENT_ROLE_MODIFIED;
                pageSaveComment = "modified details of role "+r;
                String desc = ar.defParam("desc", "");
                String reqs = ar.defParam("reqs", "");
                role.setDescription(desc);
                role.setRequirements(reqs);
            }
            else if (op.equals("Delete Role"))
            {
                eventType = HistoryRecord.EVENT_ROLE_MODIFIED;
                String confirmDelete = ar.defParam("confirmDelete", "no");
                if (!"yes".equals(confirmDelete)) {
                    throw new Exception("Please check the 'conform delete' if you really want to delete this role.");
                }
                pageSaveComment = "deleted role "+r;
                ngp.deleteRole(r);
            }
            else if(op.equals("Add Member"))
            {
                boolean sendEmail  = ar.defParam("sendEmail", null)!=null;
                HistoricActions ha = new HistoricActions(ar);
                eventType = HistoryRecord.EVENT_PLAYER_ADDED;
                pageSaveComment = "added users to role "+r+": "+id;
                ha.addMembersToRole(ngp, role, id, sendEmail);
            }
            else
            {
                throw new NGException("nugen.exceptionhandling.did.not.understand.option", new Object[]{op});
            }

            //make sure that the options above set the variables with the right values.
            if (eventType == 0 || pageSaveComment == null)
            {
                throw new ProgramLogicError("variables eventType and pageSaveComment have not been maintained properly.");
            }

            HistoryRecord.createHistoryRecord(ngp,id, HistoryRecord.CONTEXT_TYPE_ROLE,0,eventType, ar, "");
            ngp.saveContent(ar, "added user "+id+" to role "+r);

           if(go!=null){
               response.sendRedirect(go);
           }else{
               modelAndView = new ModelAndView(new RedirectView("EditRole.htm"));
               // modelAndView.addObject works in case of redirect. It adds the parameter
               // in query string.
               modelAndView.addObject("roleName",r);
           }

        }
        catch(Exception ex) {
            throw new NGException("nugen.operation.fail.project.update.role.or.member",
                    new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;
    }


    //This works for Sites as well as Projects
    @RequestMapping(value = "/{siteId}/{pageId}/roleUpdate.json", method = RequestMethod.POST)
    public void roleUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "";
        try{
            NGContainer ngc = null;
            if ("$".equals(pageId)) {
                ngc = ar.getCogInstance().getSiteByIdOrFail( siteId );
            }
            else {
                ngc = ar.getCogInstance().getProjectByKeyOrFail( pageId );
            }
            ar.setPageAccessLevels(ngc);
            //maybe this should be for admins?
            ar.assertMember("Must be a member to modify roles.");
            op = ar.reqParam("op");
            JSONObject roleInfo = getPostedObject(ar);
            String roleName = roleInfo.getString("name");
            JSONObject repo = new JSONObject();

            if ("Update".equals(op)) {
                CustomRole role = ngc.getRoleOrFail(roleName);
                role.updateFromJSON(roleInfo);
                repo = role.getJSON();
            }
            else if ("Create".equals(op)) {
                CustomRole role = ngc.createRole(roleName, "");
                role.updateFromJSON(roleInfo);
                repo = role.getJSON();
            }
            else if ("Delete".equals(op)) {
                ngc.deleteRole(roleName);
                repo.put("success",  true);
            }

            ngc.saveFile(ar, "Updated Agenda Item");
            repo.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to '"+op+"' the role.", ex);
            streamException(ee, ar);
        }
    }


    /**
     * This APPEARS to take a list of names and email addresses, and makes a list of
     * email addresses.  Should make a list of AddressListEntry objects instead, or something
     * better.  But we have routines elsewhere that do that.  This is probably redundant.
     */
    private static String pasreFullname(String fullNames) throws Exception
    {
        String assigness = "";
        String[] fullnames = UtilityMethods.splitOnDelimiter(fullNames, ',');
        for(int i=0; i<fullnames.length; i++){
            String fname = fullnames[i];
            int bindx = fname.indexOf('<');
            int length = fname.length();
            if(bindx > 0){
                fname = fname.substring(bindx+1,length-1);
            }
            assigness = assigness + "," + fname;

        }
        if(assigness.startsWith(",")){
            assigness = assigness.substring(1);
        }
        return assigness;
    }


    @RequestMapping(value = "/{siteId}/{pageId}/admin.htm", method = RequestMethod.GET)
    public ModelAndView showAdminTab(@PathVariable String siteId,
            @PathVariable String pageId, HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "nugen.project.login.msg");
            }
            //signing up as member or other operations require name and email address
            if (needsToSetName(ar)) {
                return new ModelAndView("requiredName");
            }
            if (needsToSetEmail(ar)) {
                return new ModelAndView("requiredEmail");
            }
            if(!ar.isMember()){
                ar.req.setAttribute("roleName", "Members");
                return showWarningView(ar, "nugen.project.member.msg");
            }


            request.setAttribute("tabId", "Project Settings");
            request.setAttribute("visibility_value", "3");
            return new ModelAndView("leaf_admin");
        }catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.admin.page", new Object[]{pageId,siteId} , ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/listEmail.htm", method = RequestMethod.GET)
    public ModelAndView getEmailRecordsPage( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView modelAndView = null;

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "nugen.project.upload.email.reminder.login.msg");
            }
            if(!ar.isMember()){
                request.setAttribute("roleName", "Members");
                return showWarningView(ar, "nugen.projectsettings.listEmail.memberlogin");
            }

            modelAndView=new ModelAndView("ListEmail");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.emailrecords.page", new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/{pageId}/emailSent.htm", method = RequestMethod.GET)
    public ModelAndView emailSent( @PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView modelAndView = null;

        try{
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);

            if(!ar.isLoggedIn()){
                return showWarningView(ar, "nugen.project.upload.email.reminder.login.msg");
            }
            if(!ar.isMember()){
                request.setAttribute("roleName", "Members");
                return showWarningView(ar, "nugen.projectsettings.listEmail.memberlogin");
            }

            modelAndView=new ModelAndView("EmailSent");
        }catch(Exception ex){
            throw new NGException("nugen.operation.fail.project.emailrecords.page", new Object[]{pageId,siteId} , ex);
        }
        return modelAndView;
    }

    @RequestMapping(value = "/{siteId}/{pageId}/sendNote.htm", method = RequestMethod.GET)
    public ModelAndView sendNote(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            if (!ar.isLoggedIn()) {
                return showWarningView(ar, "message.loginalert.see.page");
            }

            ar.preserveRealRequestURL();
            return new ModelAndView("SendNote");
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.sent.note.by.email.page",
                null, ex);
        }
    }



    @RequestMapping(value = "/{siteId}/{pageId}/emailGeneratorUpdate.json", method = RequestMethod.POST)
    public void emailGeneratorUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        try{
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to create an email generator.");
            JSONObject eGenInfo = getPostedObject(ar);

            String id = eGenInfo.getString("id");
            EmailGenerator eGen = null;
            if ("~new~".equals(id)) {
                eGen = ngp.createEmailGenerator();
            }
            else {
                eGen = ngp.getEmailGeneratorOrFail(id);
            }

            //this is a non persistent flag in the body ... could be a URL parameter
            boolean sendIt = eGenInfo.optBoolean("sendIt");
            eGen.updateFromJSON(eGenInfo);

            if (sendIt) {
                //need to make this work on a TIMER
                //and ... does this block while sending?
                eGen.composeAndSendEmail(ar, ngp);
            }

            ngp.saveFile(ar, "Updated Email Generator "+id);
            JSONObject repo = eGen.getJSON(ar, ngp);
            repo.write(ar.w, 2, 2);
            ar.flush();
        }
        catch(Exception ex){
            Exception ee = new Exception("Unable to update Email Generator", ex);
            streamException(ee, ar);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/streamingLinks.htm", method = RequestMethod.GET)
    public ModelAndView streamingLinks(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }

            modelAndView = new ModelAndView("StreamingLinks");
            request.setAttribute("visibility_value", "4");

            modelAndView.addObject("page", nGPage);
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Settings");
            return modelAndView;
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.personal.page", new Object[] {
                    pageId, siteId }, ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/synchronizeUpstream.htm", method = RequestMethod.GET)
    public ModelAndView synchronizeUpstream(@PathVariable String siteId, @PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            NGPage nGPage = registerRequiredProject(ar, siteId, pageId);
            ModelAndView modelAndView= memberCheckViews(ar);
            if (modelAndView!=null) {
                return modelAndView;
            }

            modelAndView = new ModelAndView("synchronizeUpstream");
            request.setAttribute("visibility_value", "4");

            modelAndView.addObject("page", nGPage);
            request.setAttribute("realRequestURL", ar.getRequestURL());
            request.setAttribute("tabId", "Project Settings");
            return modelAndView;
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.personal.page", new Object[] {
                    pageId, siteId }, ex);
        }
    }


    @RequestMapping(value = "/{siteId}/{pageId}/labelList.htm", method = RequestMethod.GET)
    public ModelAndView labelList(
            @PathVariable String pageId, @PathVariable String siteId,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {
        try {
            AuthRequest ar = AuthRequest.getOrCreate(request, response);
            registerRequiredProject(ar, siteId, pageId);
            if (!ar.isLoggedIn()) {
                return showWarningView(ar, "message.loginalert.see.page");
            }
            if(!ar.isMember()){
                request.setAttribute("roleName", "Members");
                return showWarningView(ar, "nugen.projectsettings.listEmail.memberlogin");
            }

            return new ModelAndView("LabelList");
        }
        catch (Exception ex) {
            throw new NGException("nugen.operation.fail.project.sent.note.by.email.page",
                null, ex);
        }
    }

    @RequestMapping(value = "/{siteId}/{pageId}/labelUpdate.json", method = RequestMethod.POST)
    public void labelUpdate(@PathVariable String siteId,@PathVariable String pageId,
            HttpServletRequest request, HttpServletResponse response) {
        AuthRequest ar = AuthRequest.getOrCreate(request, response);
        String op = "";
        try{
            NGPage ngp = ar.getCogInstance().getProjectByKeyOrFail( pageId );
            ar.setPageAccessLevels(ngp);
            ar.assertMember("Must be a member to modify labels.");
            op = ar.reqParam("op");
            JSONObject labelInfo = getPostedObject(ar);
            String labelName = labelInfo.getString("name");

            NGLabel label = ngp.getLabelRecordOrNull(labelName);
            if ("Create".equals(op)) {
                String editedName = labelInfo.getString("editedName");
                NGLabel other = ngp.getLabelRecordOrNull(editedName);
                if (label==null) {
                    if (other!=null) {
                        throw new Exception("Cannot create label '"+editedName+"' because a label already exists with that name.");
                    }
                    label = ngp.findOrCreateLabelRecord(editedName);
                }
                else {
                    if (!editedName.equals(labelName)) {
                        if (other!=null) {
                            throw new Exception("Cannot change label '"+labelName+"' to '"+editedName+"' because a label already exists with that name.");
                        }
                    }
                    label.setName(editedName);
                }
                label.setColor(labelInfo.getString("color"));
            }
            else if ("Delete".equals(op)) {
                if (label!=null && label instanceof LabelRecord) {
                    ngp.removeLabelRecord((LabelRecord)label);
                }
            }

            ngp.saveFile(ar, "Updated Agenda Item");
            JSONObject repo = label.getJSON();
            repo.write(ar.w, 2, 2);
            ar.flush();
        }catch(Exception ex){
            Exception ee = new Exception("Unable to modify "+op+" label.", ex);
            streamException(ee, ar);
        }
    }

}