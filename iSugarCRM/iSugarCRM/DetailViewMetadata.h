//
//  DetailViewMetadata.h
//  iSugarCRM
//
//  Created by Ved Surtani on 06/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataObjectMetadata.h"
@interface DetailViewMetadata : NSObject
@property(strong)DataObjectMetadata *objectMetadata;
@property(strong)NSString *moduleName;
@property(strong)NSDictionary *sectionItems;

-(NSDictionary*)toDictionary;
+(DetailViewMetadata*)objectFromDictionary:(NSDictionary*)dictionary;
@end