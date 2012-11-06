
//  Created by Ved Surtani on 07/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailViewRowItem.h"
#import <MessageUI/MFMailComposeViewController.h>


#define kSideMargin 8.0
#define kLabelWidth 150.0
#define KCellHeight 50.0
#define kHeightlMargin 30.0
@interface DetailViewRowItem ()
-(NSString*)valueStringWithFormat:(NSString*)format;
@end
@implementation DetailViewRowItem
@synthesize label,values,action,type;

-(CGFloat)heightForCell:(UITableView*)tableView
{
  //  NSLog(@"%@",self.label);
    CGFloat height = [[self valueStringWithFormat:nil] sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:CGSizeMake(tableView.frame.size.width - [self.label sizeWithFont:[UIFont boldSystemFontOfSize:18] constrainedToSize:CGSizeMake(170,1000) lineBreakMode:kWordWrapping].width, 10000) lineBreakMode:kWordWrapping].height;
    return KCellHeight>height?KCellHeight:(height+kHeightlMargin);
}

//TODO use OHALabel and NSAttributedString
//TODO format fields according to the type
-(UITableViewCell*)reusableCellForTableView:(UITableView*)tableView{
    UITableViewCell *cell = nil;//(UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:[self reusableCellIdentifier]];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:[self reusableCellIdentifier]];
        UILabel* label_ = [[UILabel alloc] init];
        [label_ setFont:[UIFont boldSystemFontOfSize:18]];
        label_.tag = 1000;
        [cell.contentView addSubview:label_];
        UILabel* textLabel = [[UILabel alloc] init];
        textLabel.autoresizingMask =  UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        textLabel.numberOfLines = 0;
        [textLabel setFont:[UIFont boldSystemFontOfSize:18]];
        textLabel.tag = 1001;
        textLabel.numberOfLines = 0;
        [cell.contentView addSubview:textLabel];
    }
    
    UILabel* textLabel = (UILabel*)[cell.contentView viewWithTag:1000];
    textLabel = (UILabel*)[cell.contentView viewWithTag:1000];
    
    [textLabel setFont:[UIFont boldSystemFontOfSize:18]];
    textLabel.text = [NSString stringWithFormat:@"%@: ",[self label]];
    textLabel.frame = CGRectMake(kSideMargin, 0,[self.label sizeWithFont:[UIFont boldSystemFontOfSize:18]].width + 2*kSideMargin,50);
    textLabel = (UILabel*)[cell.contentView viewWithTag:1001];
    [textLabel setFont:[UIFont systemFontOfSize:18]];
    
    textLabel.frame = CGRectMake([self.label sizeWithFont:[UIFont boldSystemFontOfSize:18]].width+2*kSideMargin, 0, cell.contentView.frame.size.width- ([self.label sizeWithFont:[UIFont boldSystemFontOfSize:18]].width+2*kSideMargin) , cell.contentView.frame.size.height);    
    
    if (![[self valueStringWithFormat:nil] isEqualToString:@"NA"]) {
        
        if ([[self reusableCellIdentifier] isEqualToString:@"phone"]) {
            textLabel.text = [self valueStringWithFormat:nil];
        } else if ([[self reusableCellIdentifier] isEqualToString:@"url"] || [[self reusableCellIdentifier] isEqualToString:@"map"]) {
            textLabel.text = [self valueStringWithFormat:nil];
        } else if ([[self reusableCellIdentifier] isEqualToString:@"email"]) {
            textLabel.text = [self valueStringWithFormat:nil];
        } else if ([[self reusableCellIdentifier] isEqualToString:@"date"]) {
            NSString *dateString = [self valueStringWithFormat:nil];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *date = [dateFormatter dateFromString:dateString];
            if (date == nil) {
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                date = [dateFormatter dateFromString:dateString];
            }
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            dateString = [dateFormatter stringFromDate:date];
            
            textLabel.text = dateString;
        } else {
            textLabel.text = [self valueStringWithFormat:nil];
        }
    } else {
        textLabel.text = [self valueStringWithFormat:nil];
        textLabel.font = [UIFont italicSystemFontOfSize:16];
    }
    return cell;
    
}
-(NSString*)valueStringWithFormat:(NSString*)format
{
    NSMutableString *displayString;
    if ([format rangeOfString:@"$"].length>0) {
        
        displayString = [NSMutableString stringWithFormat:@"%@: ",label];
    }
    else displayString =  [NSMutableString stringWithString:@""];
    int count = 0;
    
    NSMutableString *valueString = [NSMutableString stringWithString:@""];
    for(NSString *value in values)
    {
        count++;
        if (value == nil || [value isEqualToString:@""]) {
            continue;
        }
        if (count==[values count]) {
            [valueString appendString:[NSString stringWithFormat:@"%@",value]];
        }
        else {
            [valueString appendString:[NSString stringWithFormat:@"%@, ",value]];
        }
    }
    if ([valueString isEqualToString:@""]) {
        [displayString appendString:@"NA"];
    }
    else{
        [displayString appendString:valueString];
    }
    
    return displayString;
}

-(NSString*)reusableCellIdentifier
{
    if(![action isEqualToString:@""])
    {
        return [self action];
        
    } else {
        return [[self class]description];
    }
}
-(void)actionHandlerOnViewcontroller:(UIViewController *)viewController
{
    if ([action isEqualToString:@"phone"]) {
        NSMutableString *phone = [[self valueStringWithFormat:nil] mutableCopy];
        [phone replaceOccurrencesOfString:@" " 
                               withString:@"" 
                                  options:NSLiteralSearch 
                                    range:NSMakeRange(0, [phone length])];
        [phone replaceOccurrencesOfString:@"(" 
                               withString:@"" 
                                  options:NSLiteralSearch 
                                    range:NSMakeRange(0, [phone length])];
        [phone replaceOccurrencesOfString:@")" 
                               withString:@"" 
                                  options:NSLiteralSearch 
                                    range:NSMakeRange(0, [phone length])];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phone]];
        [[UIApplication sharedApplication] openURL:url];

    }
    else if ([action isEqualToString:@"date"]) {
        return;
    }
    else if ([action isEqualToString:@"email"]) {
        NSString *urlString = [NSString stringWithFormat:@"mailto:%@",[self valueStringWithFormat:nil]];
        NSURL *url = [NSURL URLWithString:urlString];
        //YET TO EXTRACT TOKENS FROM valueStringWithFormat
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
            mail.mailComposeDelegate = (id)viewController;
            [mail setToRecipients:[NSArray arrayWithObjects:[self valueStringWithFormat:nil],nil]];
            [mail setSubject:@"Subject"];
            [viewController presentViewController:mail animated:YES completion:nil];
        }else{
            [[UIApplication sharedApplication] openURL:url];
        }
    } 
    else if ([action isEqualToString:@"url"]) {
        
        NSString *urlString = [[self valueStringWithFormat:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (!([urlString hasPrefix:@"http"] || [urlString hasPrefix:@"https"])) {
            urlString = [NSString stringWithFormat:@"http://%@",[urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];

        }
    }
    else if ([action isEqualToString:@"map"]) {
        NSString* query = [self valueStringWithFormat:nil];
        query = [query stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps?q=%@",query]]];
    }
    
    else {
        return;
    }    
    
}
@end
