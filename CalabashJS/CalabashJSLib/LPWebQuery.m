//
//  LPWebQuery.m
//  CalabashJS
//
//  Created by Karl Krukow on 27/06/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import "LPWebQuery.h"
#import "LPJSONUtils.h"
#import "LPTouchUtils.h"

@implementation LPWebQuery


+(NSArray*)evaluateQuery:(NSString *)query 
                  ofType:(LPWebQueryType)type 
               inWebView:(UIWebView *)webView
        includeInvisible:(BOOL)includeInvisible
{
    NSString *jsString = nil;
    switch (type) 
    {
        case LPWebQueryTypeCSS:
            jsString = [NSString stringWithFormat:LP_QUERY_JS,query,@"css"];
            break;
            
        case LPWebQueryTypeXPATH:
            jsString = [NSString stringWithFormat:LP_QUERY_JS,query,@"xpath"];            
            break;
        case LPWebQueryTypeFreeText:
            jsString = [NSString stringWithFormat:LP_QUERY_JS, 
                        [NSString stringWithFormat:@"//node()[contains(text(),\\\"%@\\\")]", query], 
                        @"xpath"];
            break;
        default:
            NSLog(@"Unknown Query type");
            return nil;
    }

    NSMutableArray *result = [NSMutableArray array];

    if (DEBUG)
    {
        NSLog(@"JavaScript to eval:\n%@",jsString);        
    }
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:jsString];
    if (DEBUG)
    {
         NSLog(@"Result: %@",output);
    }

    NSArray *queryResult = [LPJSONUtils deserializeArray:output]; 
    
    UIWindow *window = [LPTouchUtils windowForView:webView];
    UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

    CGPoint webViewPageOffset = [self adjustOffsetForWebViewScrollPosition: webView];

    
    for (NSDictionary *d in queryResult)
    {
        NSMutableDictionary *dres = [NSMutableDictionary dictionaryWithDictionary:d];
        CGFloat left = [[dres valueForKeyPath:@"rect.left"] floatValue];
        CGFloat top = [[dres valueForKeyPath:@"rect.top"] floatValue];
        CGFloat width =  [[dres valueForKeyPath:@"rect.width"] floatValue];
        CGFloat height =  [[dres valueForKeyPath:@"rect.height"] floatValue];
        
        
        
        
        CGPoint center = CGPointMake(webViewPageOffset.x + left+width/2.0, webViewPageOffset.y + top+height/2.0);
        CGPoint windowCenter = [window convertPoint:center fromView:webView];
        CGPoint keyCenter = [frontWindow convertPoint:windowCenter fromWindow:window];
        CGPoint finalCenter = [LPTouchUtils translateToScreenCoords:keyCenter];

        if (includeInvisible || (!CGPointEqualToPoint(CGPointZero, center) && [webView pointInside:center withEvent:nil]))
        {
            NSDictionary *centerDict = (NSDictionary*)CGPointCreateDictionaryRepresentation(finalCenter);
            [dres setValue:centerDict forKey:@"center"];
            [dres setValue:webView forKey:@"webView"];
            
            [dres setValue:[NSNumber numberWithFloat:finalCenter.x] forKeyPath:@"rect.center_x"];
            [dres setValue:[NSNumber numberWithFloat:finalCenter.y] forKeyPath:@"rect.center_y"];
            
            [result addObject:dres];
            [centerDict release];
            if (DEBUG)
            {
                NSLog(@"Adding object: %@",dres);
            }

        }
    }
    return result;
}

+(CGPoint)adjustOffsetForWebViewScrollPosition:(UIWebView*) webView {
    CGPoint webViewPageOffset = CGPointMake(0, 0);
    if ([webView respondsToSelector:@selector(scrollView)]) {
        id scrollView = [webView performSelector:@selector(scrollView) withObject:nil];
        if ([scrollView respondsToSelector:@selector(contentOffset)]) {
            CGPoint scrollViewOffset = [scrollView contentOffset];
            NSString *pageOffsetStr = [webView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"];
            webViewPageOffset = CGPointMake(0, [pageOffsetStr floatValue] - scrollViewOffset.y);
        }
    }
    return webViewPageOffset;
}

@end
