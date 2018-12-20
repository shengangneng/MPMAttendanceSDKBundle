//
//  MPMSearchDepartViewController.m
//  MPMAtendence
//  部门、人员选择中的搜索功能
//  Created by gangneng shen on 2018/7/10.
//  Copyright © 2018年 gangneng shen. All rights reserved.
//

#import "MPMSearchDepartViewController.h"
#import "MPMSearchPopAnimate.h"
#import "MPMHTTPSessionManager.h"
#import "MPMShareUser.h"
#import "MPMDepartEmployeeHelper.h"
#import "MPMDepartment.h"
#import "MPMSelectDepartmentTableViewCell.h"
#import "MPMButton.h"
#import "MPMHiddenTableViewDataSourceDelegate.h"
#import "MPMGetPeopleModel.h"

@interface MPMSearchDepartViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, MPMHiddenTabelViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *headerBackButton;
// bottom
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, strong) UILabel *bottomTotalSelectedLabel;
@property (nonatomic, strong) UIButton *bottomSureButton;
@property (nonatomic, strong) UIView *headerHiddenMaskView;
@property (nonatomic, strong) UIButton *bottomUpButton;
@property (nonatomic, strong) UIView *bottomHiddenView;
@property (nonatomic, strong) UITableView *bottomHiddenTableView;
@property (nonatomic, strong) MPMHiddenTableViewDataSourceDelegate *dataSourceDelegate;
// Data
@property (nonatomic, copy) SureSelectBlock sureSelectBlock;
@property (nonatomic, weak) id<MPMSelectDepartmentViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *headerButtonTitlesArray;/** 通过这个数组的数量来决定pop回去的controller的index */
@property (nonatomic, assign) forSelectionType selectionType;
@property (nonatomic, copy) NSArray<MPMDepartment *> *searchArray;
@property (nonatomic, strong) NSMutableArray *allSelectIndexPath;
@property (nonatomic, strong) NSMutableArray *partSelectIndexPath;

@end

@implementation MPMSearchDepartViewController

- (instancetype)initWithDelegate:(id<MPMSelectDepartmentViewControllerDelegate>)delegate sureSelectBlock:(SureSelectBlock)sureBlock selectType:(forSelectionType)type titleArray:(NSMutableArray *)titleArray {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.sureSelectBlock = sureBlock;
        self.headerButtonTitlesArray = [NSMutableArray arrayWithArray:titleArray.copy];
        self.selectionType = type;
        [self setupAttributes];
        [self setupSubViews];
        [self setupConstraints];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.navigationController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    if (self.navigationController.delegate == self) {
//        self.navigationController.delegate = nil;
//    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    if (fromVC == self && [toVC isKindOfClass:[MPMSelectDepartmentViewController class]]) {
        return [[MPMSearchPopAnimate alloc] init];
    } else {
        return nil;
    }
}

#pragma mark - UITableViewDataSource && UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchArray.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTableViewHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"SearchCell";
    MPMSelectDepartmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[MPMSelectDepartmentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.checkIconImage.userInteractionEnabled = NO;
    }
    MPMDepartment *model = self.searchArray[indexPath.row];
    cell.isHuman = model.isHuman;
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (model.selectedStatus.integerValue == 1) {
        cell.checkIconImage.image = ImageName(@"setting_all");
    } else if (model.selectedStatus.integerValue == 2) {
        cell.checkIconImage.image = ImageName(@"setting_some");
    } else {
        cell.checkIconImage.image = ImageName(@"setting_none");
    }
    cell.txLabel.text = model.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self resignHeaderSearchBar];
    MPMDepartment *model = self.searchArray[indexPath.row];
    if ([self.allSelectIndexPath containsObject:indexPath]) {
        [self.allSelectIndexPath removeObject:indexPath];
        self.searchArray[indexPath.row].selectedStatus = @"0";
        if (model.isHuman) {
            // 如果是员工，则直接移除
            [[MPMDepartEmployeeHelper shareInstance] employeeArrayRemoveDepartModel:model];
        } else {
            // 如果是部门，需要移除部门下面的全部内容
            [[MPMDepartEmployeeHelper shareInstance] departmentArrayRemoveSub:model];
        }
        [[MPMDepartEmployeeHelper shareInstance] dealingAllStringData];
    } else if ([self.partSelectIndexPath containsObject:indexPath]) {
        [self.partSelectIndexPath removeObject:indexPath];
        if (model.isHuman) {
            [[MPMDepartEmployeeHelper shareInstance] employeeArrayRemoveDepartModel:model];
        } else {
            [[MPMDepartEmployeeHelper shareInstance] departmentArrayRemoveSub:model];
        }
        [[MPMDepartEmployeeHelper shareInstance] dealingAllStringData];
        self.searchArray[indexPath.row].selectedStatus = @"0";
    } else {
        [self.allSelectIndexPath addObject:indexPath];
        if (model.isHuman) {
            [[MPMDepartEmployeeHelper shareInstance] employeeArrayAddDepartModel:model];
        } else {
            [[MPMDepartEmployeeHelper shareInstance] departmentArrayAddDepartModel:model];
        }
        [[MPMDepartEmployeeHelper shareInstance] dealingAllStringData];
        self.searchArray[indexPath.row].selectedStatus = @"1";
    }
    self.bottomTotalSelectedLabel.text = [NSString stringWithFormat:@"部门:%ld个  人员:%ld人",[MPMDepartEmployeeHelper shareInstance].departments.count,[MPMDepartEmployeeHelper shareInstance].employees.count];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Target Action
- (void)popUp:(UIButton *)sender {
    sender.selected = !sender.selected;
    NSMutableArray *temp = [NSMutableArray array];
    for (MPMSchedulingDepartmentsModel *dep in [MPMDepartEmployeeHelper shareInstance].departments) {
        MPMGetPeopleModel *model = [[MPMGetPeopleModel alloc] init];
        model.name = dep.departmentName;
        model.mpm_id = dep.departmentId;
        [temp addObject:model];
    }
    for (MPMSchedulingEmplyoeeModel *emp in [MPMDepartEmployeeHelper shareInstance].employees) {
        MPMGetPeopleModel *model = [[MPMGetPeopleModel alloc] init];
        model.name = emp.employeeName;
        model.mpm_id = emp.employeeId;
        model.isHuman = @"1";
        [temp addObject:model];
    }
    self.dataSourceDelegate.peoplesArray = temp;
    [self.bottomHiddenTableView reloadData];
    if (sender.selected) {
        [UIView animateWithDuration:0.3 animations:^{
            [self.bottomUpButton mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.bottomView.mas_top).offset(-300);
                make.centerX.equalTo(self.bottomView.mas_centerX);
                make.height.equalTo(@(34));
                make.width.equalTo(@(86));
            }];
            [self.headerHiddenMaskView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.leading.trailing.equalTo(self.view);
                make.height.equalTo(@(kScreenHeight - 300));
                make.bottom.equalTo(self.view.mas_top).offset(kScreenHeight - 300 - kNavigationHeight - BottomViewHeight);
            }];
            [self.view layoutIfNeeded];
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self.bottomUpButton mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.bottomView.mas_top);
                make.centerX.equalTo(self.bottomView.mas_centerX);
                make.height.equalTo(@(34));
                make.width.equalTo(@(86));
            }];
            [self.headerHiddenMaskView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.leading.trailing.equalTo(self.view);
                make.height.equalTo(@(kScreenHeight - 300));
                make.bottom.equalTo(self.view.mas_top).offset(-kNavigationHeight);
            }];
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)hide:(UITapGestureRecognizer *)gesture {
    self.bottomUpButton.selected = NO;
    [UIView animateWithDuration:0.3 animations:^{
        [self.bottomUpButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.bottomView.mas_top);
            make.centerX.equalTo(self.bottomView.mas_centerX);
            make.height.equalTo(@(34));
            make.width.equalTo(@(86));
        }];
        [self.headerHiddenMaskView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.view);
            make.height.equalTo(@(kScreenHeight - 300));
            make.bottom.equalTo(self.view.mas_top).offset(-kNavigationHeight);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)sure:(UIButton *)sender {
    // 拿到需要的数据，跳回最初的页面
    if ([MPMDepartEmployeeHelper shareInstance].departments.count == 0 && [MPMDepartEmployeeHelper shareInstance].employees.count == 0) {
        [self showAlertControllerToLogoutWithMessage:@"请选择部门或员工" sureAction:nil needCancleButton:NO];
        return;
    }
    // 使用Delegate的方式回传数据
    if (self.delegate && [self.delegate respondsToSelector:@selector(departCompleteSelectWithDepartments:employees:)]) {
        [self.delegate departCompleteSelectWithDepartments:[MPMDepartEmployeeHelper shareInstance].departments employees:[MPMDepartEmployeeHelper shareInstance].employees];
    }
    // 使用Block的方式回传数据
    if (self.sureSelectBlock) {
        self.sureSelectBlock([MPMDepartEmployeeHelper shareInstance].departments, [MPMDepartEmployeeHelper shareInstance].employees);
    }
    // 跳回第一个进入选择部门的页面。
    UIViewController *vc = self.navigationController.viewControllers[self.navigationController.viewControllers.count-self.headerButtonTitlesArray.count-2];
    [self.navigationController popToViewController:vc animated:YES];
}

- (void)back:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self resignHeaderSearchBar];
}

- (void)resignHeaderSearchBar {
    [self.headerSearchBar resignFirstResponder];
    UIButton *cancelButton = [self.headerSearchBar valueForKey:@"cancelButton"];
    cancelButton.enabled = YES;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"%@", searchText);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self resignHeaderSearchBar];
    [self getDataOfText:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MPMHiddenTabelViewDelegate
- (void)hiddenTableView:(UITableView *)tableView deleteData:(MPMGetPeopleModel *)people {
    [self.dataSourceDelegate.peoplesArray removeObject:people];
    [self.bottomHiddenTableView reloadData];
    
    MPMDepartment *depart = [[MPMDepartment alloc] init];
    depart.mpm_id = people.mpm_id;
    depart.name = people.name;
    depart.isHuman = people.isHuman;
    if (people.isHuman) {
        [[MPMDepartEmployeeHelper shareInstance] employeeArrayRemoveDepartModel:depart];
    } else {
        [[MPMDepartEmployeeHelper shareInstance] departmentArrayRemoveSub:depart];
    }
    
    // 筛选出哪些是本页取消选中的
    for (int i = 0; i < self.searchArray.count; i++) {
        MPMDepartment *mo = self.searchArray[i];
        if ([mo.mpm_id isEqualToString:people.mpm_id]) {
            self.searchArray[i].selectedStatus = @"0";
            [self.allSelectIndexPath removeObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    // 移除全局对象里面的内容
    [[MPMDepartEmployeeHelper shareInstance].allStringData enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:depart.mpm_id]) {
            [[MPMDepartEmployeeHelper shareInstance].allStringData removeObject:obj];
        }
    }];
    [[MPMDepartEmployeeHelper shareInstance] dealingAllStringData];
    
    self.bottomTotalSelectedLabel.text = [NSString stringWithFormat:@"部门:%ld个  人员:%ld人",[MPMDepartEmployeeHelper shareInstance].departments.count,[MPMDepartEmployeeHelper shareInstance].employees.count];
    [self.tableView reloadData];
}

#pragma mark - Private Method
- (void)getDataOfText:(NSString *)text {
    if (kIsNilString(text)) {
        return;
    }
    // 需要格式化一下输入的中文字符串
    NSString *url = [NSString stringWithFormat:@"%@getQueryObject?token=%@&queryStr=%@",MPMHost,[MPMShareUser shareUser].token,text];
    NSString *encodingUrl = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSDictionary *params = @{@"token":[MPMShareUser shareUser].token,@"quertStr":text};
    [[MPMHTTPSessionManager shareManager] postRequestWithURL:encodingUrl params:params success:^(id response) {
        NSLog(@"%@",response);
        if (response[@"dataObj"] && [response[@"dataObj"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dataObj = response[@"dataObj"];
            NSMutableArray *temp = [NSMutableArray arrayWithCapacity:((NSArray *)dataObj[@"departmentMap"]).count];
            if (self.selectionType == forSelectionTypeBoth) {
                if (dataObj[@"departmentMap"] && [dataObj[@"departmentMap"] isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *dic in dataObj[@"departmentMap"]) {
                        MPMDepartment *depart = [[MPMDepartment alloc] init];
                        depart.mpm_id = dic[@"id"];
                        depart.parent_ids = dic[@"ids"];
                        depart.name = dic[@"name"];
                        [temp addObject:depart];
                    }
                }
                if (dataObj[@"employeeMap"] && [dataObj[@"employeeMap"] isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *dic in dataObj[@"employeeMap"]) {
                        MPMDepartment *depart = [[MPMDepartment alloc] init];
                        depart.mpm_id = dic[@"id"];
                        depart.parent_ids = dic[@"ids"];
                        depart.name = dic[@"name"];
                        depart.isHuman = @"1";
                        [temp addObject:depart];
                    }
                }
            } else if (self.selectionType == forSelectionTypeOnlyDepartment) {
                if (dataObj[@"departmentMap"] && [dataObj[@"departmentMap"] isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *dic in dataObj[@"departmentMap"]) {
                        MPMDepartment *depart = [[MPMDepartment alloc] init];
                        depart.mpm_id = dic[@"id"];
                        depart.parent_ids = dic[@"ids"];
                        depart.name = dic[@"name"];
                        [temp addObject:depart];
                    }
                }
            } else {
                if (dataObj[@"employeeMap"] && [dataObj[@"employeeMap"] isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *dic in dataObj[@"employeeMap"]) {
                        MPMDepartment *depart = [[MPMDepartment alloc] init];
                        depart.mpm_id = dic[@"id"];
                        depart.parent_ids = dic[@"ids"];
                        depart.name = dic[@"name"];
                        depart.isHuman = @"1";
                        [temp addObject:depart];
                    }
                }
            }
            self.searchArray = temp.copy;
            [self.allSelectIndexPath removeAllObjects];
            [self.partSelectIndexPath removeAllObjects];
            [self calculateSelection];
            [self.tableView reloadData];
        }
    } failure:^(NSString *error) {
        NSLog(@"%@",error);
    }];
}

- (void)calculateSelection {
    // 查找全选和部分选中
    for (int i = 0; i < self.searchArray.count;i++) {
        MPMDepartment *model = self.searchArray[i];
        BOOL allSelect = NO;
        BOOL partSelect = NO;
        for (MPMSchedulingEmplyoeeModel *eee in [MPMDepartEmployeeHelper shareInstance].employees) {
            if ([eee.employeeId isEqualToString:model.mpm_id]) {
                allSelect = YES;
            }
            if ([[eee.parentsId componentsSeparatedByString:@","] containsObject:model.mpm_id]) {
                partSelect = YES;
            }
        }
        for (MPMSchedulingDepartmentsModel *ddd in [MPMDepartEmployeeHelper shareInstance].departments) {
            if ([ddd.departmentId isEqualToString:model.mpm_id]) {
                allSelect = YES;
            }
            if ([[ddd.parentsId componentsSeparatedByString:@","] containsObject:model.mpm_id]) {
                partSelect = YES;
            }
        }
        if (allSelect) {
            self.searchArray[i].selectedStatus = @"1";
            [self.allSelectIndexPath addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        if (partSelect) {
            self.searchArray[i].selectedStatus = @"2";
            [self.partSelectIndexPath addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    
    self.bottomTotalSelectedLabel.text = [NSString stringWithFormat:@"部门:%ld个  人员:%ld人",[MPMDepartEmployeeHelper shareInstance].departments.count,[MPMDepartEmployeeHelper shareInstance].employees.count];
    [self.tableView reloadData];
}

#pragma mark - SetUp

- (void)setupAttributes {
    [super setupAttributes];
    if (self.selectionType == forSelectionTypeBoth) {
        self.navigationItem.title =
        self.headerSearchBar.placeholder = @"搜索部门或人员";
    } else if (self.selectionType == forSelectionTypeOnlyDepartment) {
        self.navigationItem.title =
        self.headerSearchBar.placeholder = @"搜索部门";
    } else {
        self.navigationItem.title =
        self.headerSearchBar.placeholder = @"搜索人员";
    }
    self.allSelectIndexPath = [NSMutableArray array];
    self.partSelectIndexPath = [NSMutableArray array];
    [self.headerSearchBar becomeFirstResponder];
    [self setLeftBarButtonWithTitle:@"返回" action:@selector(back:)];
    self.bottomTotalSelectedLabel.text = [NSString stringWithFormat:@"部门:%ld个  人员:%ld人",[MPMDepartEmployeeHelper shareInstance].departments.count,[MPMDepartEmployeeHelper shareInstance].employees.count];
    [self.headerHiddenMaskView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide:)]];
    [self.bottomUpButton addTarget:self action:@selector(popUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomSureButton addTarget:self action:@selector(sure:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupSubViews {
    [super setupSubViews];
    [self.view addSubview:self.headerView];
    [self.headerView addSubview:self.headerSearchBar];
    [self.view addSubview:self.tableView];
    // bottom
    [self.view addSubview:self.bottomHiddenView];
    [self.bottomHiddenView addSubview:self.bottomHiddenTableView];
    [self.view addSubview:self.bottomView];
    
    [self.view addSubview:self.headerHiddenMaskView];
    [self.view addSubview:self.bottomUpButton];
    [self.bottomView addSubview:self.bottomSureButton];
    [self.bottomView addSubview:self.bottomTotalSelectedLabel];
    [self.bottomView addSubview:self.bottomLine];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view.mas_leading);
        make.top.equalTo(self.view.mas_top);
        make.trailing.equalTo(self.view.mas_trailing);
        make.height.equalTo(@(52));
    }];
    [self.headerSearchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.headerView);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.headerView.mas_bottom);
        make.bottom.equalTo(self.bottomView.mas_top);
    }];
    // bottom
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.bottom.trailing.equalTo(self.view);
        make.height.equalTo(@(BottomViewHeight));
    }];
    [self.bottomTotalSelectedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView.mas_top).offset(BottomViewTopMargin);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(-BottomViewBottomMargin);
        make.leading.equalTo(self.bottomView.mas_leading).offset(15);
        make.trailing.equalTo(self.bottomSureButton.mas_leading).offset(-15);
    }];
    [self.bottomSureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.bottomView.mas_trailing).offset(-15);
        make.top.equalTo(self.bottomView.mas_top).offset(BottomViewTopMargin);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(-BottomViewBottomMargin);
        make.width.equalTo(@(88.5));
    }];
    [self.bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(self.bottomView);
        make.height.equalTo(@0.5);
    }];
    
    [self.bottomUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomView.mas_top);
        make.centerX.equalTo(self.bottomView.mas_centerX);
        make.height.equalTo(@(34));
        make.width.equalTo(@(86));
    }];
    [self.bottomHiddenView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.bottomUpButton.mas_bottom);
        make.height.equalTo(@300);
    }];
    [self.headerHiddenMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(kScreenHeight - 300));
        make.bottom.equalTo(self.view.mas_top).offset(-kNavigationHeight);
    }];
    [self.bottomHiddenTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bottomHiddenView);
    }];
}

#pragma mark - Lazy Init

- (UIImageView *)headerView {
    if (!_headerView) {
        _headerView = [[UIImageView alloc] init];
        _headerView.userInteractionEnabled = YES;
        _headerView.image = ImageName(@"statistics_nav");
    }
    return _headerView;
}

- (UISearchBar *)headerSearchBar {
    if (!_headerSearchBar) {
        _headerSearchBar = [[UISearchBar alloc] init];
        UIButton *cancelButton = [_headerSearchBar valueForKey:@"cancelButton"];
        cancelButton.enabled = YES;
        [cancelButton setTitle:@"返回" forState:UIControlStateNormal];
        [cancelButton setTitle:@"取消" forState:UIControlStateHighlighted];
        [cancelButton setTitleColor:kWhiteColor forState:UIControlStateNormal];
        [cancelButton setTitleColor:kWhiteColor forState:UIControlStateHighlighted];
        _headerSearchBar.delegate = self;
        _headerSearchBar.barTintColor = kClearColor;
        _headerSearchBar.backgroundImage = [[UIImage alloc] init];
        _headerSearchBar.placeholder = @"搜索部门或人员";
    }
    return _headerSearchBar;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = kTableViewBGColor;
        _tableView.allowsMultipleSelection = YES;
        [_tableView setSeparatorColor:kSeperateColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}
// bottom
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = kWhiteColor;
    }
    return _bottomView;
}
- (UIView *)bottomLine {
    if (!_bottomLine) {
        _bottomLine = [[UIView alloc] init];
        _bottomLine.backgroundColor = kSeperateColor;
    }
    return _bottomLine;
}
- (UILabel *)bottomTotalSelectedLabel {
    if (!_bottomTotalSelectedLabel) {
        _bottomTotalSelectedLabel = [[UILabel alloc] init];
        _bottomTotalSelectedLabel.text = [NSString stringWithFormat:@"选中人数(%ld)",self.allSelectIndexPath.count];
        _bottomTotalSelectedLabel.textColor = kBlackColor;
        _bottomTotalSelectedLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _bottomTotalSelectedLabel;
}
- (UIButton *)bottomSureButton {
    if (!_bottomSureButton) {
        _bottomSureButton = [MPMButton titleButtonWithTitle:@"确定" nTitleColor:kWhiteColor hTitleColor:kLightGrayColor nBGImage:ImageName(@"approval_but_determine") hImage:ImageName(@"approval_but_determine")];
    }
    return _bottomSureButton;
}
- (UIView *)bottomHiddenView {
    if (!_bottomHiddenView) {
        _bottomHiddenView = [[UIView alloc] init];
        _bottomHiddenView.backgroundColor = kTableViewBGColor;
    }
    return _bottomHiddenView;
}
- (UIButton *)bottomUpButton {
    if (!_bottomUpButton) {
        _bottomUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_bottomUpButton setImage:ImageName(@"attendence_pullup") forState:UIControlStateNormal];
        [_bottomUpButton setImage:ImageName(@"attendence_pullup") forState:UIControlStateHighlighted];
        [_bottomUpButton setImage:ImageName(@"attendence_pulldown") forState:UIControlStateSelected];
    }
    return _bottomUpButton;
}
- (UITableView *)bottomHiddenTableView {
    if (!_bottomHiddenTableView) {
        _bottomHiddenTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _bottomHiddenTableView.delegate = self.dataSourceDelegate;
        _bottomHiddenTableView.dataSource = self.dataSourceDelegate;
        _bottomHiddenTableView.separatorColor = kSeperateColor;
        _bottomHiddenTableView.backgroundColor = kWhiteColor;
        _bottomHiddenTableView.tableFooterView = [[UIView alloc] init];
    }
    return _bottomHiddenTableView;
}
- (UIView *)headerHiddenMaskView {
    if (!_headerHiddenMaskView) {
        _headerHiddenMaskView = [[UIView alloc] init];
        _headerHiddenMaskView.backgroundColor = kBlackColor;
        _headerHiddenMaskView.alpha = 0.3;
    }
    return _headerHiddenMaskView;
}

// HiddenTableViewDataSource&&Delegate
- (MPMHiddenTableViewDataSourceDelegate *)dataSourceDelegate {
    if (!_dataSourceDelegate) {
        _dataSourceDelegate = [[MPMHiddenTableViewDataSourceDelegate alloc] init];
        _dataSourceDelegate.delegate = self;
    }
    return _dataSourceDelegate;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
