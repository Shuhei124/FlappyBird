//
//  GameScene.swift
//  FlappyBird
//
//  Created by 豊田修平 on 2021/01/10.
//

import SpriteKit
import AudioToolbox

class GameScene: SKScene, SKPhysicsContactDelegate /* 追加 */ {

    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!

    // 衝突判定カテゴリー ↓追加
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4      // 0...10000
 
    // スコア用
   var score = 0
   var item_score = 0
   var scoreLabelNode:SKLabelNode!    // ←追加
   var bestScoreLabelNode:SKLabelNode!    // ←追加
   var item_scoreLabelNode:SKLabelNode!    // ←追加
   var item_bestScoreLabelNode:SKLabelNode!
    
   let userDefaults:UserDefaults = UserDefaults.standard

    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {

        // 重力を設定 (y軸のマイナス方向に重力がかかるようにする)
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self // ←追加

        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)

        // スクロールするスプライトの親ノード(ゲームオーバーで止められるようにするため)
        scrollNode = SKNode()
        addChild(scrollNode)

        // 壁用のノード ★なぜ鳥と雲はノード不要なのか?
        wallNode = SKNode()
        scrollNode.addChild(wallNode)

        // アイテム用のノード??
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()

    }
    
    // 画面をタップした時に呼ばれる(画面をタップした時に鳥を上に動かす)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 { // 追加
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 { //　リスタート実施の処理--- ここから ---
            restart()
        } // --- ここまで追加 ---
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
       func didBegin(_ contact: SKPhysicsContact) {
           // ゲームオーバーのときは何もしない(壁に当たった後、地面に必ず衝突するので2度目の処理を行わないようにする)
           if scrollNode.speed <= 0 {
               return
           }
        
            //bodyAとbodyBは衝突したSKPhysicsBodyクラスで表せるプロパティ　&:ビットアンド両方1なら1それ以外はゼロ。　||論理OR
            //★つまり、もし衝突したうちのどちらかが、scoreCategoryであったらで正しいか?
           if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
               // スコア用の物体と衝突した
               print("ScoreUp")
               score += 1
               scoreLabelNode.text = "Score:\(score)" // 現在のスコアの表示

               // ベストスコア更新か確認する
                //userDefaltsに指定したkeyで何も入っていない場合は、0が返ってくる。
               var bestScore = userDefaults.integer(forKey: "BEST")
               if score > bestScore {
                   bestScore = score
                   bestScoreLabelNode.text = "Best Score:\(bestScore)"    // ベストスコアの表示
                   userDefaults.set(bestScore, forKey: "BEST")
                   userDefaults.synchronize()
               }
            
           }
           //★&をつけるScoreCategoryのようにしなくても良いのでは?
           else if (contact.bodyA.categoryBitMask) == itemCategory ||
                        (contact.bodyB.categoryBitMask) == itemCategory {
                
                
                print("itemPointup")
                item_score += 1
                item_scoreLabelNode.text = "Item Score:\(item_score)" // 現在のスコアの表示
                var soundIdRing:SystemSoundID = 0
            
                //音を鳴らす処理
                if let soundUrl:NSURL = NSURL(fileURLWithPath:
                    Bundle.main.path(forResource: "coin001", ofType:"mp3")!) as NSURL?{
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdRing)
                    AudioServicesPlaySystemSound(soundIdRing)
                }
            
                
                var item_bestScore = userDefaults.integer(forKey: "ITEMBEST")
                if item_score > item_bestScore {
                    print("itembestPointup")
                    item_bestScore = item_score
                    item_bestScoreLabelNode.text = "Item Best Score:\(item_bestScore)"    // ベストスコアの表示
                    userDefaults.set(item_bestScore, forKey: "ITEMBEST") //★ITEM_BESTにするとうまくいかない_はuserDefaultsでは使ってはいけない?
                    userDefaults.synchronize()
                }
                //コインの削除
                if contact.bodyA.categoryBitMask == itemCategory{
                contact.bodyA.node?.removeFromParent()
                }
                if contact.bodyB.categoryBitMask == itemCategory{
                contact.bodyB.node?.removeFromParent()
                }
           } else {
               // 壁か地面と衝突した
               print("GameOver")

               // スクロールを停止させる
               scrollNode.speed = 0

               bird.physicsBody?.collisionBitMask = groundCategory

               let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
               bird.run(roll, completion:{
                   self.bird.speed = 0
               })
           }
           }
    
    //地面
    func setupGround() {
           // 地面の画像を読み込む
           let groundTexture = SKTexture(imageNamed: "ground")
           groundTexture.filteringMode = .nearest

           // 必要な枚数を計算
           let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

           // スクロールするアクションを作成
           // 左方向に画像一枚分スクロールさせるアクション
           let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)

           // 元の位置に戻すアクション
           let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

           // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
           let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

           // groundのスプライトを配置する
           for i in 0..<needNumber {
               let sprite = SKSpriteNode(texture: groundTexture)

               // スプライトの表示する位置を指定する
               sprite.position = CGPoint(
                   x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                   y: groundTexture.size().height / 2
               )

               // スプライトにアクションを設定する
               sprite.run(repeatScrollGround)

               // スプライトに物理演算を設定する(物理演算)
               sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())

               // 衝突のカテゴリー設定(衝突判定)
               sprite.physicsBody?.categoryBitMask = groundCategory

               // 衝突の時に動かないように設定する(物理演算)　★鳥に設定するのではなく、壁に設定するのはなぜか?鳥の動きを止めたいのでは?
               sprite.physicsBody?.isDynamic = false

               // スプライトを追加する
               scrollNode.addChild(sprite)
           }
       }
    

    //雲
    func setupCloud() {
         // 雲の画像を読み込む
         let cloudTexture = SKTexture(imageNamed: "cloud")
         cloudTexture.filteringMode = .nearest

         // 必要な枚数を計算
         let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

         // スクロールするアクションを作成
         // 左方向に画像一枚分スクロールさせるアクション
         let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20)

         // 元の位置に戻すアクション
         let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

         // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
         let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

         // スプライトを配置する
         for i in 0..<needCloudNumber {
             let sprite = SKSpriteNode(texture: cloudTexture)
             sprite.zPosition = -100 // 一番後ろになるようにする

             // スプライトの表示する位置を指定する
             sprite.position = CGPoint(
                 x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                 y: self.size.height - cloudTexture.size().height / 2
             )

             // スプライトにアニメーションを設定する
             sprite.run(repeatScrollCloud)

             // スプライトを追加する
             scrollNode.addChild(sprite)
         }
     }
    //壁
    func setupWall() {
            // 壁の画像を読み込む
            let wallTexture = SKTexture(imageNamed: "wall")
            wallTexture.filteringMode = .linear

            // 移動する距離を計算
            let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)

            // 画面外まで移動するアクションを作成
            let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)

            // 自身を取り除くアクションを作成
            let removeWall = SKAction.removeFromParent()

            // 2つのアニメーションを順に実行するアクションを作成
            let wallAnimation = SKAction.sequence([moveWall, removeWall])

            // 鳥の画像サイズを取得
            let birdSize = SKTexture(imageNamed: "bird_a").size()

            // 鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
            let slit_length = birdSize.height * 3

            // 隙間位置の上下の振れ幅を鳥のサイズの3倍とする
            let random_y_range = birdSize.height * 3

            // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
            let groundSize = SKTexture(imageNamed: "ground").size()
            let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
            let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2

            // 壁を生成するアクションを作成
            let createWallAnimation = SKAction.run({
                // 壁関連のノードを乗せるノードを作成
                let wall = SKNode()
                wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
                wall.zPosition = -50 // 雲より手前、地面より奥

                // 0〜random_y_rangeまでのランダム値を生成
                let random_y = CGFloat.random(in: 0..<random_y_range)
                // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
                let under_wall_y = under_wall_lowest_y + random_y

                // 下側の壁を作成　★壁のx軸が0になるのはなぜか、右から左に移動させているので一番右ではないのはなぜ?
                let under = SKSpriteNode(texture: wallTexture)
                under.position = CGPoint(x: 0, y: under_wall_y) //★この座標軸はwallのpositionの中の位置?

                // スプライトに物理演算を設定する(物理演算)
                under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
                under.physicsBody?.categoryBitMask = self.wallCategory    // ←追加

                // 衝突の時に動かないように設定する(物理演算)
                under.physicsBody?.isDynamic = false

                wall.addChild(under)

                // 上側の壁を作成 ★壁のx軸が0になるのはなぜか、右から左に移動させているので一番右ではないのはなぜ?
                let upper = SKSpriteNode(texture: wallTexture)
                upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

                // スプライトに物理演算を設定する(物理演算)
                upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
                upper.physicsBody?.categoryBitMask = self.wallCategory    // ←追加

                // 衝突の時に動かないように設定する(物理演算)
                upper.physicsBody?.isDynamic = false

                wall.addChild(upper)

                // スコアアップ用の（物体）ノード (衝突判定)--- ここから ---
                let scoreNode = SKNode()
                scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2) //★なぜこのポジションかわからない。
                scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
                scoreNode.physicsBody?.isDynamic = false
                
                //自身のカテゴリースコア用の物体(32ビットの数値)を設定
                scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
                //衝突することを判別する相手のカテゴリー(32ビットの数値)を設定
                scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
                

                wall.addChild(scoreNode)
                // --- ここまで ---

                wall.run(wallAnimation)

                self.wallNode.addChild(wall)
            })

            // 次の壁作成までの時間待ちのアクションを作成
            let waitAnimation = SKAction.wait(forDuration: 2)

            // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
            let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

            wallNode.run(repeatForeverAnimation)
        }
    //鳥
    func setupBird() {
            // 鳥の画像を2種類読み込む
            let birdTextureA = SKTexture(imageNamed: "bird_a")
            birdTextureA.filteringMode = .linear
            let birdTextureB = SKTexture(imageNamed: "bird_b")
            birdTextureB.filteringMode = .linear

            // 2種類のテクスチャを交互に変更するアニメーションを作成
            let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
            let flap = SKAction.repeatForever(texturesAnimation)

            // スプライトを作成 (x,y)=(フレームの幅*0.2,高さ*0.7)に表示
            bird = SKSpriteNode(texture: birdTextureA)
            bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)

            // 物理演算を設定(★physicsWorld.gravityで重力を設定しているのに、以下で物理演算をかけられるのは何故か?
            //★半径を設定しているのはなぜか?直径だと何か問題がある?
            bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)

            // 衝突した時に回転させない
            bird.physicsBody?.allowsRotation = false    // ←追加

            // 衝突のカテゴリー設定(衝突判定)
            bird.physicsBody?.categoryBitMask = birdCategory    //categoryBitMaskは自分のカテゴリーを設定
                //collisionBitMaskは当たった時に跳ね返る動作をする相手を設定する。
            bird.physicsBody?.collisionBitMask = groundCategory | wallCategory    // ←追加
                //衝突することを判別する相手のカテゴリー(32ビットの数値)を設定(鳥はグラウンドか壁に衝突する)
            bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemCategory   // ←追加

            // アニメーションを設定
            bird.run(flap)

            // スプライトを追加する
            addChild(bird)
        }

    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 40)
        scoreLabelNode.fontSize = 20
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.fontSize = 20
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        //アイテムのスコア
        item_score = 0
        item_scoreLabelNode = SKLabelNode()
        item_scoreLabelNode.fontColor = UIColor.black
        item_scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 80)
        item_scoreLabelNode.fontSize = 20
        item_scoreLabelNode.zPosition = 100 // 一番手前に表示する
        item_scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        item_scoreLabelNode.text = "Item Score:\(item_score)"
        self.addChild(item_scoreLabelNode)

        item_bestScoreLabelNode = SKLabelNode()
        item_bestScoreLabelNode.fontColor = UIColor.black
        item_bestScoreLabelNode.fontSize = 20
        item_bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 100)
        item_bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        item_bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        let item_bestScore = userDefaults.integer(forKey: "Item BEST")
        item_bestScoreLabelNode.text = "Item Best Score:\(item_bestScore)"
        self.addChild(item_bestScoreLabelNode)
        
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"    // ←追加
        item_score = 0
        item_scoreLabelNode.text = "Item Score:\(item_score)"    // ←追加

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        wallNode.removeAllChildren()
        itemNode.removeAllChildren()

        bird.speed = 1
        scrollNode.speed = 1
    }
    
    //アイテム
    func setupItem() {
            // 壁の画像を読み込む
            let itemTexture = SKTexture(imageNamed: "coin")
            itemTexture.filteringMode = .linear

            // 移動する距離を計算
            let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)

            // 画面外まで移動するアクションを作成
            let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:2)

            // 自身を取り除くアクションを作成
            let removeItem = SKAction.removeFromParent()

            // 2つのアニメーションを順に実行するアクションを作成
            let itemAnimation = SKAction.sequence([moveItem, removeItem])


            // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
            let groundSize = SKTexture(imageNamed: "ground").size()
            let random_y_range = self.frame.size.height - groundSize.height - itemTexture.size().height
            let under_item_lowest_y = groundSize.height + itemTexture.size().height/2

            // アイテムを生成するアクションを作成
            let createitemAnimation = SKAction.run({
                // アイテム関連のノードを乗せるノードを作成
                let item = SKNode()
                //★ここがよく分からない。なぜこの位置なのか。
                item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0)
                item.zPosition = -60 // 雲より手前、地面より奥??

                // 0〜random_y_rangeまでのランダム値を生成
                let random_y = CGFloat.random(in: 0..<random_y_range)
                // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
                let item_y = under_item_lowest_y + random_y


                //コインのspritenodeの作成
                let coin = SKSpriteNode(texture: itemTexture)
                coin.position = CGPoint(x: 0, y: item_y) //★ここがよく分からない。

                // スプライトに物理演算を設定する(物理演算)
                coin.physicsBody = SKPhysicsBody(circleOfRadius: itemTexture.size().height / 2)
                coin.physicsBody?.categoryBitMask = self.itemCategory    // ←追加

                // 衝突の時に動かないように設定する(物理演算) falseだとぶつかった時に動かなくなる
                //★SKPhysicsBodyクラスのisDynamicプロパティにfalseを設定することで重力の影響を受けず、
                //衝突したとき動かないようにします。
                coin.physicsBody?.isDynamic = false

                item.addChild(coin)
 
                //衝突することを判別する相手のカテゴリー(32ビットの数値)を設定(コインは鳥に衝突する)
                coin.physicsBody?.contactTestBitMask = self.birdCategory    // ←追加

                item.run(itemAnimation)

                self.itemNode.addChild(item)
            })
            // 次の壁作成までの時間待ちのアクションを作成
            let waitAnimation = SKAction.wait(forDuration: 2)

            // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
            let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createitemAnimation, waitAnimation]))

            itemNode.run(repeatForeverAnimation)
        }
    
}


//
