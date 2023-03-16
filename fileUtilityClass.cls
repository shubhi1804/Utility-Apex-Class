public class fileUtilityClass {
    
    public static void insertStringFormatFile(String conLocation, String pathOnClient, String title, String fileContent, String recordId){
        
        ContentVersion conVersion      = new ContentVersion();
        conVersion.ContentLocation     = conLocation; // Origin of the document (S,E,L)
        conVersion.PathOnClient        = pathOnClient; // field that determines the FileType
        conVersion.Title               = title; // Display name of the files
        conVersion.VersionData         = EncodingUtil.base64Decode(fileContent); // converting your binary string to Blob
        insert conVersion;    //Insert ContentVersion
        
        
        // First get the Content Document Id from ContentVersion Object
        Id contentDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVersion.Id].ContentDocumentId;
        
        
        //create ContentDocumentLink  record 
        ContentDocumentLink conDocLink     = New ContentDocumentLink();
        conDocLink.LinkedEntityId          = recordId; // Specify any Object ID (Standard Object/Custom Object)
        conDocLink.ContentDocumentId       = contentDocument;  //ContentDocumentId Id from ContentVersion
        conDocLink.shareType               = 'V'; //Viewer permission: The user can explicitly view but not edit the shared file.
        insert conDocLink;
        
    }
    
    public static void insertBlobFormatFile(String conLocation, String pathOnClient, String title, Blob fileContent, String recordId){
        
        String base64Content = EncodingUtil.Base64Encode( 
            Blob.valueOf( 'fileContent' ) 
        );
        System.debug( 'Base64 Content is ' + base64Content );
        Blob blobContent = EncodingUtil.base64Decode( base64Content );
        System.debug( 'Decoded Base64 value is ' + blobContent.toString() );
        
        ContentVersion conVerObject = new ContentVersion(
            ContentLocation         = conLocation,
            Title                   = title,
            PathOnClient            = pathOnClient,
            VersionData             = blobContent 
        );
        insert conVerObject;
        conVerObject = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: conVerObject.Id];
        
        ContentDocumentLink conDocLinkObj  = new ContentDocumentLink(
            ContentDocumentId              = conVerObject.ContentDocumentId,
            LinkedEntityId                 = recordId,
            Visibility                     = 'AllUsers' //Specifies whether this file is available to all users, internal users, or shared users. 
        );
        insert conDocLinkObj;

    }
    
    public static Map<Id, List<ContentVersion>> getRelatedFiles(List<Id> parentIdList) {

        Map<Id, List<ContentVersion>> fileByParentId    = new Map<Id, List<ContentVersion>>();
        Map<Id, Id> contentIdByParentId                 = new Map<Id, Id>();

        for(ContentDocumentLink contentLink : [Select Id, ContentDocumentId, LinkedEntityId From ContentDocumentLink Where LinkedEntityId IN :parentIdList]) {
            contentIdByParentId.put(contentLink.ContentDocumentId, contentLink.LinkedEntityId);
        }

        if(!contentIdByParentId.isEmpty()) {
            for(ContentVersion cv :  [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentIdByParentId.keySet()]) {
               
                if(!fileByParentId.containsKey(contentIdByParentId.get(cv.ContentDocumentId))) {
                    fileByParentId.put(contentIdByParentId.get(cv.ContentDocumentId), new List<ContentVersion>());
                }
                
                fileByParentId.get(contentIdByParentId.get(cv.ContentDocumentId)).add(cv);
            }
        }
        
        return fileByParentId;
    } 
    
    public static  List<ContentVersion >  getRelatedFilesByRecId(String recId) {
        
        List<contentDocumentLink > listCDL = [ SELECT ContentDocumentid, LinkedEntityid FROM contentDocumentLink WHERE LinkedEntityid = :recId];
        
        Set<Id> setContentDocumentIds = new Set <Id>();
        
        for( contentDocumentLink  rec : listCDL  ){
            
            setContentDocumentIds .add(rec.ContentDocumentid);
        }
        List<ContentVersion > listContentVersion  = [SELECT Id  FROM ContentVersion  WHERE ContentDocumentId IN :setContentDocumentIds];
        return listContentVersion;
    } 
    
    public static String uploadAttachment(String recordId, String attachmentBody, String attachmentName, String attachmentId) {
        
        if(recordId != null) {
            if(attachmentBody != null) {
                Attachment att = getAttachment(attachmentId);
                String newBody = '';
                if(att.Body != null) {
                    newBody = EncodingUtil.base64Encode(att.Body);
                }
                newBody += attachmentBody;
                att.Body = EncodingUtil.base64Decode(newBody);
                if(attachmentId == null) {
                    att.Name = attachmentName;
                    att.parentId =recordId;
                }
                upsert att;
                return att.Id;
            } else {
                return 'Attachment Body was null';
            }
        } else {
            return 'Record Id was null';
        }
    }
    
     private static Attachment getAttachment(String attId) {
         
         List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE Id =: attId];
         if(attachments.isEmpty()) {
             Attachment a = new Attachment();
             return a;
         } else {
             return attachments[0];
         }
     }
}
