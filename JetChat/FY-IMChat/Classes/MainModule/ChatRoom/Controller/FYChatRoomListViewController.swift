//
//  FYChatRoomListViewController.swift
//  FY-JetChat
//
//  Created by iOS.Jet on 2019/8/18.
//  Copyright © 2019 Jett. All rights reserved.
//

import UIKit
import WCDBSwift

fileprivate let kGroupedChatCellIdentifier = "kGroupedChatCellIdentifier"

class FYChatRoomListViewController: FYBaseViewController {

    // MARK: - var lazy
    
    var dataSource: [FYMessageChatModel] = []
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("删除所有群组".rLocalized(), for: .normal)
        button.theme.titleColor(from: themed { $0.FYColor_Main_TextColor_V11 }, for: .normal)
        button.titleLabel?.font = .PingFangRegular(16)
        button.sizeToFit()
        button.isHidden = true
        button.rxTapClosure { [weak self] in
            self?.showClearAlert()
        }
        return button
    }()
    
    
    // MARK: - life cycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deleteButton.isHidden = dataSource.count > 0 ? false : true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "群聊".rLocalized()
        
        loadGroupData()
        registerGroupNoti()
    }
    
    @objc private func loadGroupData() {
        dataSource = FYDBQueryHelper.shared.qureyFromChatsWithType(2)
        DispatchQueue.main.async {
            self.plainTabView.reloadData()
            self.deleteButton.isHidden = self.dataSource.count > 0 ? false : true
        }
    }
    
    private func registerGroupNoti() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadGroupData), name: .kNeedRefreshChatInfoList, object: nil)
    }
    
    override func makeUI() {
        super.makeUI()
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: deleteButton)
        
        let rightBarButtonItem = UIBarButtonItem(title: "加入群".rLocalized(), style: .plain, target: self, action: #selector(addGroupData))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        plainTabView.register(FYContactsTableViewCell.self, forCellReuseIdentifier: kGroupedChatCellIdentifier)
        view.addSubview(plainTabView)
        plainTabView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalTo(self.view.snp.bottomMargin)
            }
        }
    }
    
    @objc private func showClearAlert() {
        
        EasyAlertView.customAlert(title: "确定删除全部群组吗？".rLocalized(), message: "删除后，会话记录也将清除".rLocalized(), confirm: "确定".rLocalized(), cancel: "取消".rLocalized(), vc: self, confirmBlock: {
            self.removerGroupData()
        }, cancelBlock: {
            
        })
    }
    
    @objc private func addGroupData() {
        var uid = 10
        if let lastUser = dataSource.last {
            uid = lastUser.uid! + 1
        }
        
        let chat = FYMessageChatModel()
        chat.uid = uid
        chat.name = "好好学习群：\(uid)"
        chat.avatar = "https://img2.woyaogexing.com/2019/11/10/c133b080fcfd43e1916e74eaea4c631b!400x400.jpeg"
        chat.isShowName = true
        chat.chatType = 2 //群聊
        
        dataSource.append(chat)
        DispatchQueue.main.async {
            self.plainTabView.reloadData {
                self.scrollToBottom()
                FYDBQueryHelper.shared.insertFromChat(chat)
                self.deleteButton.isHidden = self.dataSource.count > 0 ? false : true
            }
        }
    }
    
    @objc private func removerGroupData() {
        dataSource.removeAll()
        DispatchQueue.main.async {
            self.plainTabView.reloadData {
                self.scrollToBottom()
                FYDBQueryHelper.shared.deleteFromChatsWithType(2)
                FYDBQueryHelper.shared.deleteFromMessagesWithType(2)
                self.deleteButton.isHidden = self.dataSource.count > 0 ? false : true
                // 刷新会话列表
                NotificationCenter.default.post(name: .kNeedRefreshSesstionList, object: nil)
            }
        }
    }

    
    /// 滚到底部
    private func scrollToBottom(_ animated: Bool = true) {
        
        plainTabView.scrollToLast(at: .bottom, animated: animated)
    }
}



// MARK: - UITableViewDataSource && Delegate

extension FYChatRoomListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kGroupedChatCellIdentifier) as! FYContactsTableViewCell
        if let model = dataSource[safe: indexPath.row] {
            cell.model = model
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let model = dataSource[safe: indexPath.row] {
            let chatModel = FYDBQueryHelper.shared.qureyFromChatId(model.uid!)
            let chatVC = FYChatBaseViewController(chatModel: chatModel)
            navigationController?.pushViewController(chatVC, animated: true)
            // clear
            clearCurrentBadge(chatModel)
        }
    }
    
    /// 清空角标
    private func clearCurrentBadge(_ group: FYMessageChatModel) {
        
        if FYDBQueryHelper.shared.queryFromSesstionsUnReadCount() > 0 {
            if let uid = group.uid {
                group.unReadCount = 0
                FYDBQueryHelper.shared.updateFromChatModel(group, uid: uid)
                // 刷新会话列表
                NotificationCenter.default.post(name: .kNeedRefreshSesstionList, object: nil)
            }
        }
    }
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }
}
