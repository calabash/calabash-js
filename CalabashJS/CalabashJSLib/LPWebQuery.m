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

NSString *const LP_QUERY_JS = @"(function(){function isHostMethod(object,property){var t=typeof object[property];return t==='function'||(!!(t==='object'&&object[property]))||t==='unknown';}var NODE_TYPES={1:'ELEMENT_NODE',2:'ATTRIBUTE_NODE',3:'TEXT_NODE',9:'DOCUMENT_NODE'};function computeRectForNode(object){var res={},boundingBox;if(isHostMethod(object,'getBoundingClientRect')){boundingBox=object.getBoundingClientRect();res['rect']=boundingBox;res['rect'].center_x=boundingBox.left+Math.floor(boundingBox.width/2);res['rect'].center_y=boundingBox.top+Math.floor(boundingBox.height/2);}res.nodeType=NODE_TYPES[object.nodeType]||res.nodeType+' (Unexpected)';res.nodeName=object.nodeName;res.id=object.id||'';res['class']=object.className||'';if(object.href){res.href=object.href;}if(object.hasOwnProperty('value')){res.value=object.value||'';}res.html=object.outerHTML||'';res.textContent=object.textContent;return res;}function toJSON(object){var res,i,N,spanEl,parentEl;if(typeof object==='undefined'){throw {message:'Calling toJSON with undefined'};}else{if(object instanceof Text){parentEl=object.parentElement;if(parentEl){spanEl=document.createElement('calabash');spanEl.style.display='inline';spanEl.innerHTML=object.textContent;parentEl.replaceChild(spanEl,object);res=computeRectForNode(spanEl);res.nodeType=NODE_TYPES[object.nodeType];delete res.nodeName;delete res.id;delete res['class'];parentEl.replaceChild(object,spanEl);}else{res=object;}}else{if(object instanceof Node){res=computeRectForNode(object);}else{if(object instanceof NodeList||(typeof object=='object'&&object&&typeof object.length==='number'&&object.length>0&&typeof object[0]!=='undefined')){res=[];for(i=0,N=object.length;i<N;i++){res[i]=toJSON(object[i]);}}else{res=object;}}}}return res;}var exp='%@',queryType='%@',nodes=null,res=[],i,N;try{if(queryType==='xpath'){nodes=document.evaluate(exp,document,null,XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,null);for(i=0,N=nodes.snapshotLength;i<N;i++){res[i]=nodes.snapshotItem(i);}}else{res=document.querySelectorAll(exp);}}catch(e){return JSON.stringify({error:'Exception while running query: '+exp,details:e.toString()});}return JSON.stringify(toJSON(res));})();";

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
            return nil;
    }

    NSMutableArray *result = [NSMutableArray array];

    NSString *output = [webView stringByEvaluatingJavaScriptFromString:jsString];


    NSArray *queryResult = [LPJSONUtils deserializeArray:output];

    UIWindow *window = [LPTouchUtils windowForView:webView];
    UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

    CGPoint webViewPageOffset = [self adjustOffsetForWebViewScrollPosition: webView];

    for (NSDictionary *d in queryResult)
    {
        NSMutableDictionary *dres = [NSMutableDictionary dictionaryWithDictionary:d];
        CGFloat center_x = [[dres valueForKeyPath:@"rect.center_x"] floatValue];
        CGFloat center_y = [[dres valueForKeyPath:@"rect.center_y"] floatValue];
      
        CGPoint center = CGPointMake(webViewPageOffset.x + center_x, webViewPageOffset.y + center_y);
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
