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

package org.socialbiz.cog;

import java.io.StringWriter;
import java.net.URLEncoder;
import java.util.List;
import java.util.Vector;

import org.socialbiz.cog.spring.NGWebUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
 * People create this, and this creates emails, sent possibly in
 * the future, and records the fact that the emails have been sent.
 */
public class EmailGenerator extends DOMFace {

    public EmailGenerator(Document nDoc, Element nEle, DOMFace p) {
        super(nDoc, nEle, p);

        //schema migration stuff
        if (getState()<EG_STATE_DRAFT) {
            setState(EG_STATE_DRAFT);
        }
    }

    public String getId() throws Exception {
        return getAttribute("id");
    }

    public void setId(String newVal) throws Exception {
        setAttribute("id", newVal);
    }

    public final int EG_STATE_DRAFT     = 1;
    public final int EG_STATE_SCHEDULED = 2;
    public final int EG_STATE_SENT      = 3;

    public int getState() {
        return safeConvertInt(getAttribute("state"));
    }
    public void setState(int newVal) {
        setAttribute("state", Integer.toString(newVal));
    }


    public String getFrom() throws Exception {
        return getScalar("from");
    }

    public void setFrom(String newVal) throws Exception {
        setScalar("from", newVal);
    }

    public String getSubject() throws Exception {
        return getScalar("subject");
    }

    public void setSubject(String newVal) throws Exception {
        setScalar("subject", newVal);
    }

    public String getIntro() throws Exception {
        return getScalar("intro");
    }

    public void setIntro(String newVal) throws Exception {
        setScalar("intro", newVal);
    }

    public long getSendDate() throws Exception {
        return safeConvertLong(getScalar("sendDate"));
    }
    public void setSendDate(long newVal) throws Exception {
        setScalar("sendDate", Long.toString(newVal));
    }

    public List<String> getRoleNames() throws Exception {
        return getVector("roleName");
    }

    public void setRoleNames(Vector<String> newVal) throws Exception {
        setVector("roleName", newVal);
    }

    public List<String> getAlsoTo() throws Exception {
        return getVector("alsoTo");
    }

    public void setAlsoTo(Vector<String> newVal) throws Exception {
        setVector("alsoTo", newVal);
    }

    public String getNoteId() throws Exception {
        return getScalar("noteId");
    }

    public void setNoteId(String newVal) throws Exception {
        setScalar("noteId", newVal);
    }

    public String getMeetingId() throws Exception {
        return getScalar("meetingId");
    }

    public void setMeetingId(String newVal) throws Exception {
        setScalar("meetingId", newVal);
    }

    /**
     * A list of document universalid values which have been selected
     * by the user for attachments to the email.
     */
    public List<String> getAttachments() throws Exception {
        return getVector("attachment");
    }

    public void setAttachments(Vector<String> newVal) throws Exception {
        setVector("attachment", newVal);
    }


    public boolean getExcludeResponders() throws Exception {
        return "true".equals(getAttribute("excludeResponders"));
    }

    public void setExcludeResponders(boolean newVal) throws Exception {
        if (newVal) {
            setAttribute("excludeResponders", "true");
        }
        else {
            setAttribute("excludeResponders", null);
        }
    }

    public boolean getIncludeSelf() throws Exception {
        return "true".equals(getAttribute("includeSelf"));
    }

    public void setIncludeSelf(boolean newVal) throws Exception {
        if (newVal) {
            setAttribute("includeSelf", "true");
        }
        else {
            setAttribute("includeSelf", null);
        }
    }

    public boolean getMakeMembers() throws Exception {
        return "true".equals(getAttribute("makeMembers"));
    }

    public void setMakeMembers(boolean newVal) throws Exception {
        if (newVal) {
            setAttribute("makeMembers", "true");
        }
        else {
            setAttribute("makeMembers", null);
        }
    }

    /**
     * This boolean controls whether the body of the NOTE is included
     * in the message, or whether the note is simply linked.
     */
    public boolean getIncludeBody() throws Exception {
        return "true".equals(getAttribute("includeBody"));
    }

    public void setIncludeBody(boolean newVal) throws Exception {
        if (newVal) {
            setAttribute("includeBody", "true");
        }
        else {
            setAttribute("includeBody", null);
        }
    }

    /**
     * This boolean determines whether to include the attachments as
     * actual email attachments, or just to link to them in the message.
     */
    public boolean getAttachFiles() throws Exception {
        return "true".equals(getAttribute("attachFiles"));
    }

    public void setAttachFiles(boolean newVal) throws Exception {
        if (newVal) {
            setAttribute("attachFiles", "true");
        }
        else {
            setAttribute("attachFiles", null);
        }
    }



    public void composeAndSendEmail(AuthRequest ar, NGPage ngp) throws Exception {
        Vector<OptOutAddr> sendTo = new Vector<OptOutAddr>();
        for (String roleName : getRoleNames()) {
            NGRole role = ngp.getRole(roleName);
            if (role!=null) {
                OptOutAddr.appendUsersFromRole(ngp, roleName, sendTo);
            }
        }
        boolean makeMember = getMakeMembers();
        NGRole memberRole = ngp.getRoleOrFail("Members");
        for (String address : getAlsoTo()) {
            AddressListEntry enteredAddress = AddressListEntry.parseCombinedAddress(address);
            OptOutAddr.appendOneUser(new OptOutDirectAddress(enteredAddress), sendTo);
            if(makeMember && !ngp.primaryOrSecondaryPermission(enteredAddress)) {
                memberRole.addPlayer(enteredAddress);
            }
        }
        NoteRecord noteRec = ngp.getNoteByUidOrNull(getNoteId());
        if (noteRec!=null && getExcludeResponders()) {
            for (LeafletResponseRecord llr : noteRec.getResponses()) {
                String responder = llr.getUser();
                OptOutAddr.removeFromList(sendTo, responder);
            }
        }
        if (getIncludeSelf()) {
            AddressListEntry aleself = new AddressListEntry(ar.getUserProfile());
            OptOutAddr.appendOneUser(new OptOutDirectAddress(aleself), sendTo);
        }

        StringBuffer historyNameList = new StringBuffer();
        boolean needComma = false;
        for (OptOutAddr ooa : sendTo) {
            String addr = ooa.getEmail();
            if (addr!=null && addr.length()>0) {
                sendMessageToUser(ar, ngp, noteRec, ooa);
                if (needComma) {
                    historyNameList.append(",");
                }
                historyNameList.append(addr);
                needComma= true;
            }
        }
        setState(EG_STATE_SENT);
        setSendDate(ar.nowTime);
    }

    private void sendMessageToUser(AuthRequest ar, NGPage ngp, NoteRecord noteRec, OptOutAddr ooa)
            throws Exception  {
        String userAddress = ooa.getEmail();
        if (userAddress==null || userAddress.length()==0)
        {
            //don't send anything if the user does not have an email address
            return;
        }

        StringWriter bodyWriter = new StringWriter();
        AuthRequest clone = new AuthDummy(ar.getUserProfile(), bodyWriter, ar.getCogInstance());
        clone.setNewUI(true);
        clone.retPath = ar.baseURL;
        clone.write("<html><body>");

        //if you really want the files attached to the email message, then include a list of
        //their attachment ids here
        List<AttachmentRecord> attachList = NGWebUtils.getSelectedAttachments(ar, ngp);
        Vector<String> attachIds = new Vector<String>();
        for (String attId : getAttachments()) {
            AttachmentRecord aRec = ngp.findAttachmentByUidOrNull(attId);
            attachList.add(aRec);
            if (getAttachFiles()) {
                attachIds.add(aRec.getId());
            }
        }

        String meetId = getMeetingId();
        MeetingRecord meeting = null;
        if (meetId!=null && meetId.length()>0) {
            meeting = ngp.findMeeting(meetId);
            for (AgendaItem ai : meeting.getAgendaItems()) {
                for (String doc : ai.getDocList()) {
                    AttachmentRecord aRec = ngp.findAttachmentByUidOrNull(doc);
                    attachList.add(aRec);
                    if (getAttachFiles()) {
                        attachIds.add(aRec.getId());
                    }
                }
            }
        }


        writeNoteAttachmentEmailBody(clone, ngp, noteRec, ooa.getAssignee(), getIntro(),
                getIncludeBody(), attachList, meeting);

        clone.write("</body></html>");

        EmailSender.containerEmail(ooa, ngp, getSubject(), bodyWriter.toString(), getFrom(), attachIds, ar.getCogInstance());
    }

    //TODO: change this to use a TEMPLATE approach, when loops are allowed
    public static void writeNoteAttachmentEmailBody(AuthRequest ar,
            NGPage ngp, NoteRecord selectedNote,
            AddressListEntry ale, String intro, boolean includeBody,
            List<AttachmentRecord> selAtt, MeetingRecord meeting) throws Exception {
        ar.write("<p><b>Note From:</b> ");
        ar.getUserProfile().writeLink(ar);
        ar.write(" &nbsp; <b>Project:</b> ");
        ngp.writeContainerLink(ar, 100);
        ar.write("</p>");
        ar.write("\n<div class=\"leafContent\" >");
        WikiConverter.writeWikiAsHtml(ar, intro);
        ar.write("</div>");
        if (selAtt != null && selAtt.size() > 0) {
            ar.write("</p>");
            ar.write("\n<p><b>Attachments:</b> (click links for secure access to documents)<ul> ");
            for (AttachmentRecord att : selAtt) {
                ar.write("\n<li><a href=\"");
                ar.write(ar.retPath);
                ar.write(ar.getResourceURL(ngp, "docinfo" + att.getId()
                        + ".htm?"));
                ar.write(AccessControl.getAccessDocParams(ngp, att));
                ar.write("\">");
                ar.writeHtml(att.getNiceName());
                ar.write("</a></li> ");
            }
            ar.write("</ul></p>");
        }
        if (selectedNote != null) {
            String noteURL = ar.retPath + ar.getResourceURL(ngp, selectedNote)
                    + "?" + AccessControl.getAccessNoteParams(ngp, selectedNote)
                    + "&emailId=" + URLEncoder.encode(ale.getEmail(), "UTF-8");
            if (includeBody) {
                ar.write("\n<p><i>The note is copied below. You can access the most recent, ");
                ar.write("most up to date version on the web at the following link:</i> <a href=\"");
                ar.write(noteURL);
                ar.write("\" title=\"Access the latest version of this message\"><b>");
                if (selectedNote.getSubject() != "" && selectedNote.getSubject() != null) {
                    ar.writeHtml(selectedNote.getSubject());
                }
                else {
                    ar.writeHtml("Note Link");
                }
                ar.write("</b></a></p>");
                ar.write("\n<hr/>\n");
                ar.write("\n<div class=\"leafContent\" >");
                WikiConverter.writeWikiAsHtml(ar, selectedNote.getWiki());
                ar.write("\n</div>");
            }
            else {
                ar.write("\n<p><i>Access the web page using the following link:</i> <a href=\"");
                ar.write(noteURL);
                ar.write("\" title=\"Access the latest version of this note\"><b>");
                String noteSubj = selectedNote.getSubject();
                if (noteSubj==null || noteSubj.length()==0) {
                    noteSubj = "Note has no name.";
                }
                ar.writeHtml(noteSubj);
                ar.write("</b></a></p>");
            }

            String choices = selectedNote.getChoices();
            String[] choiceArray = UtilityMethods
                    .splitOnDelimiter(choices, ',');
            UserProfile up = ale.getUserProfile();
            if (up != null && choiceArray.length > 0) {
                selectedNote.getOrCreateUserResponse(up);
            }
            if (choiceArray.length > 0 & includeBody) {
                ar.write("\n<p><font color=\"blue\"><i>This request has some response options.  Use the <a href=\"");
                ar.write(noteURL);
                ar.write("#Response\" title=\"Response form on the web\">web page</a> to respond to choose between: ");
                int count = 0;
                for (String ach : choiceArray) {
                    count++;
                    ar.write(" ");
                    ar.write(Integer.toString(count));
                    ar.write(". ");
                    ar.writeHtml(ach);
                }
                ar.write("</i></font></p>\n");
            }
        }

        if (meeting!=null) {
            String meetingURL = ar.retPath + ar.getResourceURL(ngp, "meetingFull.htm?id="+meeting.getId());
            ar.write("\n<p><i>The meeting agenda is copied below. You can access the most recent, ");
            ar.write("most up to date version on the web at the following link:</i> <a href=\"");
            ar.write(meetingURL);
            ar.write("\" title=\"Access the latest version of this meeting\"><b>");
            ar.writeHtml(meeting.getName());
            ar.write("</b></a></i><p>");

            String meetWiki = meeting.generateWikiRep(ar,  ngp);
            ar.write("\n<hr/>\n<div class=\"leafContent\" >");
            WikiConverter.writeWikiAsHtml(ar, meetWiki);
            ar.write("</div>");
        }
    }


    public JSONObject getJSON(AuthRequest ar, NGPage ngp) throws Exception {
        JSONObject obj = new JSONObject();
        obj.put("id", getId());
        obj.put("from", getFrom());
        obj.put("subject", getSubject());
        obj.put("state", getState());
        obj.put("sendDate", getSendDate());
        obj.put("roleNames", constructJSONArray(getRoleNames()));
        obj.put("alsoTo", constructJSONArray(getAlsoTo()));
        obj.put("intro", getIntro());
        obj.put("excludeResponders", getExcludeResponders());
        obj.put("includeSelf", getIncludeSelf());
        obj.put("makeMembers", getMakeMembers());
        obj.put("includeBody", getIncludeBody());
        obj.put("attachFiles", getAttachFiles());

        JSONArray attachmentInfo = new JSONArray();
        for (String attId : getAttachments()) {
            AttachmentRecord atRec = ngp.findAttachmentByUidOrNull(attId);
            if (atRec!=null) {
                attachmentInfo.put(atRec.getJSON4Doc(ar, ngp));
            }
        }
        obj.put("attachments", attachmentInfo);

        String noteId = getNoteId();
        if (noteId!=null && noteId.length()>0) {
            NoteRecord nr = ngp.getNoteByUidOrNull(noteId);
            if (nr!=null) {
                obj.put("noteInfo", nr.getJSONWithWiki(ngp));
            }
        }
        String meetingId = getMeetingId();
        if (meetingId!=null && meetingId.length()>0) {
            MeetingRecord meet = ngp.findMeetingOrNull(meetingId);
            if (meet!=null) {
                obj.put("meetingInfo", meet.getFullJSON(ar, ngp));
            }
        }

        return obj;
    }

    public void updateFromJSON(JSONObject obj) throws Exception {
        if (obj.has("from")) {
            setFrom(obj.getString("from"));
        }
        if (obj.has("subject")) {
            setSubject(obj.getString("subject"));
        }
        if (obj.has("intro")) {
            setIntro(obj.getString("intro"));
        }

        //NO SET STATE from JSON!!

        if (obj.has("sendDate")) {
            setSendDate(obj.getLong("sendDate"));
        }
        if (obj.has("noteInfo")) {
            JSONObject noteObj = obj.getJSONObject("noteInfo");
            setNoteId(noteObj.getString("universalid"));
        }
        if (obj.has("roleNames")) {
            setRoleNames(constructVector(obj.getJSONArray("roleNames")));
        }
        if (obj.has("alsoTo")) {
            setAlsoTo(constructVector(obj.getJSONArray("alsoTo")));
        }
        if (obj.has("attachments")) {
            //this pulls the universal id from the attachment info object, nothing else
            JSONArray attInfo = obj.getJSONArray("attachments");
            Vector<String> newSetting = new Vector<String>();
            for (int i=0; i<attInfo.length(); i++) {
                JSONObject oneAtt = attInfo.getJSONObject(i);
                String uid = oneAtt.getString("universalid");
                newSetting.add(uid);
            }
            setAttachments(newSetting);
        }
        if (obj.has("excludeResponders")) {
            setExcludeResponders(obj.getBoolean("excludeResponders"));
        }
        if (obj.has("includeSelf")) {
            setIncludeSelf(obj.getBoolean("includeSelf"));
        }
        if (obj.has("makeMembers")) {
            setMakeMembers(obj.getBoolean("makeMembers"));
        }
        if (obj.has("includeBody")) {
            setIncludeBody(obj.getBoolean("includeBody"));
        }
        if (obj.has("attachFiles")) {
            setAttachFiles(obj.getBoolean("attachFiles"));
        }
        if (obj.has("meetingInfo")) {
            JSONObject attInfo = obj.getJSONObject("meetingInfo");
            setMeetingId( attInfo.getString("id") );
        }
    }

}