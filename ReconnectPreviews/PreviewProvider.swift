// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2026 Jason Morley
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

import Cocoa
import Quartz

// TODO: Is this needed?
class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    

    /*
     Use a QLPreviewProvider to provide data-based previews.
     
     To set up your extension as a data-based preview extension:

     - Modify the extension's Info.plist by setting
       <key>QLIsDataBasedPreview</key>
       <true/>
     
     - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

     - Change the NSExtensionPrincipalClass to this class.
       e.g.
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
     
     - Implement providePreview(for:)
     */
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {

        //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
        //To return Data of a supported content type:
        
        let contentType = UTType.plainText // replace with your data type
        
        let reply = QLPreviewReply.init(dataOfContentType: contentType, contentSize: CGSize.init(width: 800, height: 800)) { (replyToUpdate : QLPreviewReply) in

            let data = Data("Hello world".utf8)
            
            //setting the stringEncoding for text and html data is optional and defaults to String.Encoding.utf8
            replyToUpdate.stringEncoding = .utf8

            //initialize your data here
            
            return data
        }
                
        return reply
    }
}
