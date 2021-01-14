//
//  ViewController.swift
//  FlappyBird
//
//  Created by 豊田修平 on 2021/01/10.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // SKViewに型を変換する
        let skView = self.view as! SKView

        // FPSを表示する
        skView.showsFPS = true

        // ノードの数を表示する
        skView.showsNodeCount = true

        // ビューと同じサイズでシーンを作成する
        let scene = GameScene(size:skView.frame.size)

        // ビューにシーンを表示する(SkViewの上にsceneを表示)
        skView.presentScene(scene)
    }
    
    //ステータスバー(時間とか電波とか表示されている部分)を消す
    override var prefersStatusBarHidden: Bool {
        get{
            return true
        }
    }
}
