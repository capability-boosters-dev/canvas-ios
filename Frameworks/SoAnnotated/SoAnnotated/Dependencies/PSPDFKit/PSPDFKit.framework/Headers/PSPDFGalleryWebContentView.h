//
//  PSPDFGalleryWebContentView.h
//  PSPDFKit
//
//  Copyright (c) 2014-2016 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "PSPDFGalleryContentView.h"

/// `PSPDFGalleryWebContentView` displays a web item.
PSPDF_CLASS_AVAILABLE @interface PSPDFGalleryWebContentView : PSPDFGalleryContentView

/// The web view of the content view.
@property (nonatomic, readonly, nullable) UIView *webView;

@end
