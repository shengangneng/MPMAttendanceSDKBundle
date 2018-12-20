//
//  MPMHTTPSessionManager.m
//  MPMAtendence
//  网络请求单例
//  Created by gangneng shen on 2018/4/13.
//  Copyright © 2018年 gangneng shen. All rights reserved.
//

#import "MPMHTTPSessionManager.h"
#import "MPMLoginViewController.h"
#import "MPMShareUser.h"
#import "MPMAttendanceHeader.h"

static MPMHTTPSessionManager *instance;
@interface MPMHTTPSessionManager()
@property (nonatomic, strong) AFNetworkReachabilityManager *checkNetworkManager;
@end

@implementation MPMHTTPSessionManager

- (instancetype)initManager {
    self = [super init];
    if (self) {
        self.manager = [AFHTTPSessionManager manager];
        self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.checkNetworkManager = [AFNetworkReachabilityManager manager];
    }
    return self;
}

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
         instance = [[MPMHTTPSessionManager alloc] initManager];
    });
    return instance;
}


#pragma mark - Public Method

- (void)startNetworkMonitoringWithStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus))block {
    dispatch_async(kGlobalQueueDEFAULT, ^{
        [self.checkNetworkManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(status);
            });
        }];
        [self.checkNetworkManager startMonitoring];
    });
}

/** 带有SVProgressHUD的请求 */
- (void)getRequestWithURL:(NSString *)url params:(id)params loadingMessage:(NSString *)loadingMessage success:(void(^)(id))success failure:(void(^)(NSString *))failure {
    [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = responseObject;
            NSNumber *succ = dic[@"success"];
            if (succ.intValue == 1) {
                success(responseObject);
            } else {
                NSString *errorMessage = [dic[@"message"] isKindOfClass:[NSNull class]] ? ([dic[@"dataObj"] isKindOfClass:[NSString class]] ? dic[@"dataObj"] : @"error") : dic[@"message"];
                failure(errorMessage);
                if ([errorMessage containsString:@"用户信息已失效"]) {
//                    [self showAlertControllerToLogoutWithMessage:@"用户信息已失效，请重新登录"];
                } else {
                }
            }
        } else {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error.localizedDescription);
    }];
}

- (void)postRequestWithURL:(NSString *)url params:(id)params loadingMessage:(NSString *)loadingMessage success:(void(^)(id))success failure:(void(^)(NSString *))failure {
    [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = responseObject;
            NSNumber *succ = dic[@"success"];
            if (succ.intValue == 1) {
                success(responseObject);
            } else {
                NSString *errorMessage = [dic[@"message"] isKindOfClass:[NSNull class]] ? ([dic[@"dataObj"] isKindOfClass:[NSString class]] ? dic[@"dataObj"] : @"error") : dic[@"message"];
                failure(errorMessage);
                if ([errorMessage containsString:@"用户信息已失效"]) {
//                    [self showAlertControllerToLogoutWithMessage:@"用户信息已失效，请重新登录"];
                } else {
                }
            }
        } else {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error.localizedDescription);
    }];
}

/** 不带SVProgressHUD的请求 */
- (void)getRequestWithURL:(NSString *)url params:(id)params success:(void(^)(id response))success failure:(void(^)(NSString *error))failure {
    [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = responseObject;
            NSNumber *succ = dic[@"success"];
            if (succ.intValue == 1) {
                success(responseObject);
            } else {
                NSString *errorMessage = [dic[@"message"] isKindOfClass:[NSNull class]] ? ([dic[@"dataObj"] isKindOfClass:[NSString class]] ? dic[@"dataObj"] : @"error") : dic[@"message"];
                failure(errorMessage);
                if ([errorMessage containsString:@"用户信息已失效"]) {
//                    [self showAlertControllerToLogoutWithMessage:@"用户信息已失效，请重新登录"];
                }
            }
        } else {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error.localizedDescription);
    }];
}

- (void)postRequestWithURL:(NSString *)url params:(id)params success:(void(^)(id response))success failure:(void(^)(NSString *error))failure {
    [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = responseObject;
            NSNumber *succ = dic[@"success"];
            if (succ.intValue == 1) {
                success(responseObject);
            } else {
                NSString *errorMessage = [dic[@"message"] isKindOfClass:[NSNull class]] ? ([dic[@"dataObj"] isKindOfClass:[NSString class]] ? dic[@"dataObj"] : @"error") : dic[@"message"];
                failure(errorMessage);
                if ([errorMessage containsString:@"用户信息已失效"]) {
//                    [self showAlertControllerToLogoutWithMessage:@"用户信息已失效，请重新登录"];
                }
            }
        } else {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error.localizedDescription);
    }];
}


#pragma mark -
- (void)showAlertControllerToLogoutWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 这里用weakAlert，否则会导致循环引用
    __weak typeof (UIAlertController *) weakAlert = alertController;
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        kAppDelegate.window.rootViewController = [[MPMLoginViewController alloc] init];
        [[MPMShareUser shareUser] clearData];
    }];
    [weakAlert addAction:sure];
    [kAppDelegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
