//
//  LPWebQuery.m
//  CalabashJS
//
//  Created by Karl Krukow on 27/06/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import "LPWebQuery.h"
#import "LPJSONUtils.h"
@implementation LPWebQuery


+(NSArray*)evaluateQuery:(NSString *)query 
                  ofType:(LPWebQueryType)type 
               inWebView:(UIWebView *)webView
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
    
    CGPoint webViewPoint = [webView convertPoint:webView.bounds.origin toView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
       
    for (NSDictionary *d in queryResult) 
    {
        NSMutableDictionary *dres = [NSMutableDictionary dictionaryWithDictionary:d];
        CGFloat left = [[dres valueForKeyPath:@"rect.left"] floatValue];
        CGFloat top = [[dres valueForKeyPath:@"rect.top"] floatValue];
        CGFloat width =  [[dres valueForKeyPath:@"rect.width"] floatValue];
        CGFloat height =  [[dres valueForKeyPath:@"rect.height"] floatValue];
        
        
        CGPoint center = CGPointMake(left+width/2.0, top+height/2.0);            
        CGPoint screenCenter = CGPointMake(webViewPoint.x + center.x, webViewPoint.y + center.y);            
        if (!CGPointEqualToPoint(CGPointZero, center) && [webView pointInside:center withEvent:nil])
        {
            NSDictionary *centerDict = (__bridge_transfer NSDictionary*)CGPointCreateDictionaryRepresentation(screenCenter);
            [dres setValue:centerDict forKey:@"center"];
            [dres setValue:webView forKey:@"webView"];
            [result addObject:dres];                
            if (DEBUG)
            {
                NSLog(@"Adding object: %@",dres);
            }

        }
    }
    return result;
}

@end
