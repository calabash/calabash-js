//
//  LPWebQuery.h
//  CalabashJS
//
//  Created by Karl Krukow on 27/06/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const LP_QUERY_JS;

typedef enum LPWebQueryType 
{
    LPWebQueryTypeCSS,
    LPWebQueryTypeXPATH,
    LPWebQueryTypeFreeText
    
} LPWebQueryType;

@interface LPWebQuery : NSObject

+(NSArray*)evaluateQuery:(NSString *)query 
                  ofType:(LPWebQueryType)type 
               inWebView:(UIWebView *)webView
        includeInvisible:(BOOL)includeInvisible;

@end
