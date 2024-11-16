//
//  ContentView.swift
//  Spamo
//
//  Created by Ben Blodgett on 11/9/24.
//

import SwiftUI
struct ContentView: View {
    @State public var loopingTimers : [Timer] = []
    @State private var gameStarted = false
    @State private var endLoop = false
    @State private var upgradeScreenOpen = false
    var body: some View{
        ZStack{
            
            if (upgradeScreenOpen){
                upgradeScreen
            }
            else if (gameStarted){
                game
            }
            else{
                background
                titleScreen
            }
        }
    }
    
    @State var difficultyNum = 2
    @State var difficultyText = "Medium"
    @State var difficultyColor = Color.yellow
    
    //title screen
    var titleScreen: some View{
        VStack {
            Text("Spamo")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()

            Button(action: {
                difficultyNum+=1
                if (difficultyNum > 4){
                    difficultyNum = 1
                }
                if (difficultyNum == 1){
                    difficultyText = "Easy"
                    difficultyColor = Color.green
                }
                if (difficultyNum == 2){
                    difficultyText = "Medium"
                    difficultyColor = Color.yellow
                }
                if (difficultyNum == 3){
                    difficultyText = "Hard"
                    difficultyColor = Color.orange
                }
                if (difficultyNum == 4){
                    difficultyText = "Impossible"
                    difficultyColor = Color.red
                }
            }){
                Text(difficultyText)
                    .font(.title)
                    .padding()
                    .background(difficultyColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
            // Start the game by changing the state variable
                attackCooldown = 4.0-Double(difficultyNum)
                playerHealth = 9.0-Double(difficultyNum*2)
                playerMaxHealth = 9.0-Double(difficultyNum*2)
                bossNum = 1
                gameStarted = true
                upgradeScreenOpen = true
                resetEverything()
                resetUpgrades()
            }) {
            Text("Start")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    //dots
    private static let particles = 30
    struct Dot: Identifiable, Equatable{
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
    }
    @State private var dots: [Dot] = []
    @State private var dotsSpawned = false
    func spawnDots(){
        if (!dotsSpawned){
            dotsSpawned = true;
            for index in 0..<30 {
                Timer.scheduledTimer(withTimeInterval: delay*Double(index), repeats: false){_ in
                    dots.append(Dot(position:CGPoint(x:CGFloat.random(in:0...UIScreen.main.bounds.width), y: -100), size: CGFloat.random(in:0...8)+1))
                }
            }
            Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
                _ in
                updateDotsPositions()
            }
        }
    }
    func updateDotsPositions(){
        for index in dots.indices.reversed() {
            if dots[index].position.y < UIScreen.main.bounds.height+50 {
                dots[index].position.y += dots[index].size * (100 * delay)
            } else {
                dots[index].position.y = -50;
                dots[index].position.x = CGFloat.random(in:0...UIScreen.main.bounds.width)
            }
        }
    }
    
    var background : some View{
        ZStack{
            Color.black.ignoresSafeArea().onAppear{spawnDots()}
            ForEach(dots){
                dot in
                Image("dot").resizable().frame(width:dot.size,height:dot.size).position(dot.position).onAppear{}
            }
        }
    }
    
    //character
    @State private var pos: CGPoint = CGPoint(x:200,y:400)
    @State private var mousePos : CGPoint = CGPoint(x:200,y:400)
    @State private var playerSize = CGSize(width:56,height:90)
    @State private var damageCooldown = 0.0;
    func checkForCollisions(){
        pos = CGPoint(x:200,y:400)
        mousePos = CGPoint(x:200,y:400)
        playerSize = CGSize(width:56,height:90)
        damageCooldown = 0.0
        loopingTimers.append(Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            pos = CGPoint(x:(3*pos.x+mousePos.x)/4,y:(3*pos.y+mousePos.y)/4)
        })
        loopingTimers.append(Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            damageCooldown -= delay;
            if (damageCooldown <= 0.0){
                let playerRect = CGRect(origin: pos, size: playerSize).offsetBy(dx: -playerSize.width/2, dy: -playerSize.height/2)
                let bossRect = CGRect(origin: bossPos, size: bossSize).offsetBy(dx: -bossSize.width/2, dy: -bossSize.height/2)
                if playerRect.intersects(bossRect){
                    playerHealth-=1;
                    if (playerHealth == 0.0){
                        for timer in loopingTimers{
                            timer.invalidate()
                        }
                        loopingTimers = []
                        gameStarted = false
                        endLoop = true
                    }
                    damageCooldown = 1.0
                    return
                }
                for missile in bossMissiles{
                    if (missile.movementMethod != "Ghost"){
                        let missileRect = CGRect(origin: missile.position, size: missile.size).offsetBy(dx: -missile.size.width/2, dy: -missile.size.height/2)
                        if (playerRect.intersects(missileRect)){
                            playerHealth-=1;
                            if (playerHealth == 0.0){
                                for timer in loopingTimers{
                                    timer.invalidate()
                                }
                                loopingTimers = []
                                gameStarted = false
                                endLoop = true
                            }
                            damageCooldown = 1.0
                            bossMissiles.remove(at: bossMissiles.firstIndex(of:missile)!)
                            return
                        }
                    }
                }
            }
        })
    }
    //character health bar
    @State private var playerHealth = 5.0
    @State private var playerMaxHealth = 5.0
    var playerHealthBar: some View{
        ZStack(alignment: .leading) {
                    Rectangle()
                .frame(width: UIScreen.main.bounds.width,height: 20)
                .foregroundColor(.red)
                        .cornerRadius(10)
                    Rectangle()
                        .frame(width: playerHealth / playerMaxHealth * UIScreen.main.bounds.width, height: 20)
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
    }
    
    //missles
    struct Missile: Identifiable, Equatable{
        let id = UUID()
        var position: CGPoint
        var size: CGSize = CGSize(width: 20, height: 75)
        var rotation: CGFloat = 0
        var missileSpeed = 400.0
        var missileDamage = 1.0
        var missileID: String
        var movementMethod: String
    }
    struct Attack: Equatable{
        var size: CGSize = CGSize(width: 20, height: 75)
        var posOffset: CGPoint = CGPoint(x: 0, y: 0)
        var rotation: CGFloat = 0
        var missileSpeed = 400.0
        var missileDamage = 1.0
        var attackSpeed = 1.0
        var cooldown = 1.0
        var missileID: String = "1"
        var movementMethod: String = "Forward"
    }
    @State private var missiles:[Missile] = []
    @State private var attacks:[Attack] = [Attack()]
    @State private var availableAttacks:[Attack] = []
    @State private var initialAttacks:[Attack] = [
        Attack(posOffset: CGPoint(x:30,y:0),attackSpeed: 4.0),Attack(posOffset: CGPoint(x:-30,y:0),attackSpeed: 4.0),
        Attack(size: CGSize(width:40,height:40),missileSpeed: 150.0,missileDamage: 0.04,attackSpeed: 1.5,missileID: "2",movementMethod: "Rotating0"),
        Attack(rotation: 135,missileSpeed: 200.0,missileDamage: 2.0,missileID: "2",movementMethod: "Slashing225"),
        Attack(attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:45,attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:90,attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:135,attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:180,attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:-45,attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:-90,attackSpeed: 8,movementMethod: "Bouncing3"),Attack(rotation:-135,attackSpeed: 8,movementMethod: "Bouncing3"),
    ]
    func shoot(){
        loopingTimers.append(Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { _ in
            for index in attacks.indices{
                attacks[index].cooldown -= delay
                if (attacks[index].cooldown <= 0){
                    let startPos = CGPoint(x:pos.x+attacks[index].posOffset.x,y:pos.y+attacks[index].posOffset.y)
                    missiles.append(Missile(position: startPos,rotation: attacks[index].rotation,missileSpeed: attacks[index].missileSpeed,missileDamage: attacks[index].missileDamage,missileID: attacks[index].missileID,movementMethod: attacks[index].movementMethod))
                    attacks[index].cooldown = attacks[index].attackSpeed
                }
            }
        })
        loopingTimers.append(Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            updateMissilePositions()
        })
    }
    private let delay = 0.02;
    func updateMissilePositions(){
        let bossRect = CGRect(origin: bossPos, size: bossSize).offsetBy(dx: -bossSize.width/2, dy: -bossSize.height/2)
        for index in missiles.indices.reversed() {
            let missileRect = CGRect(origin: missiles[index].position, size: missiles[index].size).offsetBy(dx: -missiles[index].size.width/2, dy: -missiles[index].size.height/2)
            var removed = false
            if (missileRect.intersects(bossRect)){
                bossHealth-=missiles[index].missileDamage
                if (!missiles[index].movementMethod.starts(with: "Rotating")){
                    missiles.remove(at: index)
                    removed = true
                }
                if (bossHealth <= 0 && !upgradeScreenOpen){
                    bossNum+=1;
                    endLoop = true
                    upgradeScreenOpen = true
                    resetUpgrades()
                    for timer in loopingTimers{
                        timer.invalidate()
                    }
                    loopingTimers = []
                }
            }
            if (!removed) {
                if (missiles[index].movementMethod == "Forward"){
                    missiles[index].position.y -= cos(missiles[index].rotation * CGFloat.pi / 180) * missiles[index].missileSpeed * delay
                    missiles[index].position.x += sin(missiles[index].rotation * CGFloat.pi / 180) * missiles[index].missileSpeed * delay
                    if(missiles[index].position.x < -missiles[index].size.width || missiles[index].position.x > UIScreen.main.bounds.width+missiles[index].size.width || missiles[index].position.y < -missiles[index].size.height || missiles[index].position.y > UIScreen.main.bounds.height+missiles[index].size.height){
                        missiles.remove(at: index)
                    }
                }
                else if (missiles[index].movementMethod.starts(with: "Bouncing")){
                    missiles[index].position.y -= cos(missiles[index].rotation * CGFloat.pi / 180) * missiles[index].missileSpeed * delay
                    missiles[index].position.x += sin(missiles[index].rotation * CGFloat.pi / 180) * missiles[index].missileSpeed * delay
                    var bounce = false
                    if(missiles[index].position.x < missiles[index].size.width/2 || missiles[index].position.x > UIScreen.main.bounds.width-missiles[index].size.width/2){
                        bounce = true
                        missiles[index].rotation = -missiles[index].rotation
                    }
                    if(missiles[index].position.y < missiles[index].size.height/2 || missiles[index].position.y > UIScreen.main.bounds.height-missiles[index].size.height/2){
                        bounce = true
                        missiles[index].rotation = 180-missiles[index].rotation
                    }
                    if (bounce){
                        let num = Int(missiles[index].movementMethod.suffix(from: missiles[index].movementMethod.index(missiles[index].movementMethod.startIndex, offsetBy: 8)))
                        if (num == 1){
                            missiles[index].movementMethod = "Forward"
                        }
                        else{
                            missiles[index].movementMethod = "Bouncing" + String(num!-1)
                        }
                    }
                }
                else if (missiles[index].movementMethod.starts(with: "Rotating")){
                    let string = missiles[index].movementMethod.suffix(from: missiles[index].movementMethod.index(missiles[index].movementMethod.startIndex, offsetBy: 8))
                    let rotation = Double(string)!
                    missiles[index].rotation += missiles[index].missileSpeed * delay * 4
                    missiles[index].position.y -= cos(rotation * CGFloat.pi / 180) * missiles[index].missileSpeed * delay
                    missiles[index].position.x += sin(rotation * CGFloat.pi / 180) * missiles[index].missileSpeed * delay
                    if(missiles[index].position.x < -missiles[index].size.width || missiles[index].position.x > UIScreen.main.bounds.width+missiles[index].size.width || missiles[index].position.y < -missiles[index].size.height || missiles[index].position.y > UIScreen.main.bounds.height+missiles[index].size.height){
                        missiles.remove(at: index)
                    }
                }
                else if (missiles[index].movementMethod.starts(with: "Slashing")){
                    let string = missiles[index].movementMethod.suffix(from: missiles[index].movementMethod.index(missiles[index].movementMethod.startIndex, offsetBy: 8))
                    let endRotation = Double(string)!
                    missiles[index].rotation += missiles[index].missileSpeed * delay
                    let rotation = missiles[index].rotation
                    missiles[index].position.y = pos.y + cos(rotation * CGFloat.pi / 180)*50
                    missiles[index].position.x =  pos.x - sin(rotation * CGFloat.pi / 180)*50
                    if (missiles[index].rotation >= endRotation){
                        missiles.remove(at: index)
                    }
                }
            }
        }
    }
    
    //bosses
    @State private var bossNum = 1
    @State private var bossPos: CGPoint = CGPoint(x:UIScreen.main.bounds.width/2,y:100)
    @State private var bossSize = CGSize(width:150,height:65)
    func resetBoss(){
        playerHealth = playerMaxHealth
        bossMissiles = []
        bossPos = CGPoint(x:UIScreen.main.bounds.width/2,y:100)
        if (bossNum == 1){
            bossSize = CGSize(width:150,height:65)
            bossHealth = 50.0
            bossMaxHealth = 50.0
        }
        if (bossNum == 2){
            bossSize = CGSize(width:185,height:125)
            bossHealth = 50.0
            bossMaxHealth = 50.0
        }
        if (bossNum==3){
            bossSize = CGSize(width:125,height:130)
            bossHealth = 50.0
            bossMaxHealth = 50.0
        }
    }
    //boss attacks
    @State private var attackCooldown = 2.0
    func runBossAttacks(){
        Timer.scheduledTimer(withTimeInterval: attackCooldown, repeats: false){
            _ in
            if (!endLoop){
                let timeToRun = runBossAttack()
                Timer.scheduledTimer(withTimeInterval: timeToRun, repeats: false){
                    _ in
                    runBossAttacks()
                }
            }
            else{
                endLoop = false
            }
        }
    }
    func runBossAttack() -> CGFloat{
        if (bossNum == 1){
            let bossAttackNum = Int.random(in: 1...3)
            if (bossAttackNum == 1){
                return runBoss1Attack1()
            }
            if (bossAttackNum == 2){
                return runBoss1Attack2()
            }
            if (bossAttackNum == 3){
                return runBoss1Attack3()
            }
        }
        if (bossNum == 2){
            let bossAttackNum = Int.random(in: 1...4)
            if(bossAttackNum == 1){
                return runBoss2Attack1()
            }
            if (bossAttackNum == 2){
                return runBoss2Attack2()
            }
            if (bossAttackNum == 3){
                return runBoss2Attack3()
            }
            if (bossAttackNum == 4){
                return runBoss1Attack2()
            }
        }
        if (bossNum == 3){
            let bossAttackNum = Int.random(in: 1...4)
            if (bossAttackNum == 1){
                return runBoss3Attack1()
            }
            if (bossAttackNum == 2){
                return runBoss3Attack2()
            }
            if (bossAttackNum == 3){
                return runBoss3Attack3()
            }
            if (bossAttackNum == 4){
                return runBoss3Attack4()
            }
        }
        return 0.0
    }
    func runBoss1Attack1() -> CGFloat{
        let goalPos : CGFloat = CGFloat.random(in:bossSize.width/2...UIScreen.main.bounds.width-bossSize.width/2)
        let timeToRun : CGFloat = abs(bossPos.x-goalPos)/100
        var time : CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            timer in
            time += delay
            if (goalPos > bossPos.x){
                bossPos.x+=100*delay
            }
            else{
                bossPos.x-=100*delay
            }
            if (time >= timeToRun){
                timer.invalidate()
                bossPos.x = goalPos
            }
        }
        Timer.scheduledTimer(withTimeInterval: timeToRun, repeats: false){
            _ in
            let normalX : CGFloat = bossPos.x-bossSize.width/2
            let normalY : CGFloat = bossPos.y+bossSize.height/2
            for index in 0..<4{
                let newX : CGFloat = bossSize.width*CGFloat(index)/3
                let missile = BossMissile(position: CGPoint(x:normalX+newX,y:normalY), missileId: 1, rotation: 0, movementMethod: "Forward", missileSpeed: 400.0)
                bossMissiles.append(missile)
            }
        }
        return timeToRun
    }
    func runBoss1Attack2() -> CGFloat{
        for index in 0...((Int(UIScreen.main.bounds.height)-100)/100){
            let newY : CGFloat = CGFloat(index * 100 + 100)
            let missile = BossMissile(position: CGPoint(x:CGFloat(((index+1)%2))*UIScreen.main.bounds.width,y:newY),size: CGSize(width:75,height:20), missileId: 1, rotation: CGFloat(90 + (index%2)*180), movementMethod: "Ghost", missileSpeed: 200.0, transparency: 0.5)
            bossMissiles.append(missile)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false){_ in
                for index in bossMissiles.indices{
                    if (bossMissiles[index] == missile){
                        bossMissiles[index].movementMethod = "Forward"
                        bossMissiles[index].transparency = 1
                        break
                    }
                }
            }
        }
        return UIScreen.main.bounds.width/200 + 1
    }
    func runBoss1Attack3() -> CGFloat{
        for index in 0..<3{
            Timer.scheduledTimer(withTimeInterval: CGFloat(index)/2, repeats: false){
                _ in
                let atanValue = atan(Double((pos.x-bossPos.x)/(pos.y-bossPos.y)))*180/Double.pi
                let missile = BossMissile(position: bossPos,size: CGSize(width:75,height:20), missileId: 1, rotation: -atanValue, movementMethod: index == 2 ? "Forward" : "Bouncing"+String(2-index), missileSpeed: 300.0)
                bossMissiles.append(missile)
            }
        }
        return 3.0+UIScreen.main.bounds.height/300
    }
    func runBoss2Attack1() -> CGFloat{
        let goalPos : CGFloat = CGFloat.random(in:bossSize.width/2...UIScreen.main.bounds.width-bossSize.width/2)
        let timeToRun : CGFloat = abs(bossPos.x-goalPos)/100
        var time : CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            timer in
            time += delay
            if (goalPos > bossPos.x){
                bossPos.x+=100*delay
            }
            else{
                bossPos.x-=100*delay
            }
            if (time >= timeToRun){
                timer.invalidate()
                bossPos.x = goalPos
            }
        }
        Timer.scheduledTimer(withTimeInterval: timeToRun, repeats: false){
            _ in
            let normalX : CGFloat = bossPos.x-bossSize.width/2
            let normalY : CGFloat = bossPos.y+bossSize.height/2
            for index in 0..<3{
                let newX : CGFloat = bossSize.width*CGFloat(index)/4
                let missile = BossMissile(position: CGPoint(x:normalX+newX,y:normalY), missileId: 1, rotation: 0, movementMethod: "Forward", missileSpeed: 400.0)
                bossMissiles.append(missile)
            }
        }
        Timer.scheduledTimer(withTimeInterval: timeToRun+((playerSize.height+75)/300), repeats: false){
            _ in
            let normalX : CGFloat = bossPos.x-bossSize.width/2
            let normalY : CGFloat = bossPos.y+bossSize.height/2
            for index in 2..<5{
                let newX : CGFloat = bossSize.width*CGFloat(index)/4
                let missile = BossMissile(position: CGPoint(x:normalX+newX,y:normalY), missileId: 1, rotation: 0, movementMethod: "Forward", missileSpeed: 400.0)
                bossMissiles.append(missile)
            }
        }
        return timeToRun+((playerSize.height+75)/300)
    }
    func runBoss2Attack2() -> CGFloat{
        for index in 0..<9{
            Timer.scheduledTimer(withTimeInterval: CGFloat(Double(index)/3.0), repeats: false){
                _ in
                var pos2: CGPoint
                var bounces: Bool
                if (index%3==0){
                    pos2 = CGPoint(x: -pos.x, y: pos.y)
                    bounces = true;
                }
                else if (index%3==1){
                    pos2 = pos
                    bounces = false
                }
                else{
                    pos2 = CGPoint(x: (UIScreen.main.bounds.width*2)-pos.x, y: pos.y)
                    bounces = true;
                }
                let atanValue = atan(Double((pos2.x-bossPos.x)/(pos2.y-bossPos.y)))*180/Double.pi
                let missile = BossMissile(position: bossPos,size: CGSize(width:75,height:20), missileId: 1, rotation: -atanValue, movementMethod: bounces ? "Bouncing1" : "Forward", missileSpeed: 300.0)
                bossMissiles.append(missile)
            }
        }
        return 3.0+UIScreen.main.bounds.height/300
    }
    func runBoss2Attack3() -> CGFloat{
        for index in 0...3{
            Timer.scheduledTimer(withTimeInterval: 1.5*Double(index), repeats: false){
                _ in
                let missile1 = BossMissile(position: CGPoint(x:10,y:pos.y),size: CGSize(width:75,height:20), missileId: 1, rotation: -90, movementMethod: "Ghost", missileSpeed: 400.0, transparency: 0.5)
                let missile2 = BossMissile(position: CGPoint(x:pos.x,y:UIScreen.main.bounds.height-20),size: CGSize(width:75,height:20), missileId: 1, rotation: 180, movementMethod: "Ghost", missileSpeed: 400.0, transparency: 0.5)
                let pos2 = CGPoint(x:CGFloat.random(in: 10...UIScreen.main.bounds.width-10),y:CGFloat.random(in: 50...UIScreen.main.bounds.height-20))
                var atanValue = atan(Double((pos.x-pos2.x)/(pos.y-pos2.y)))*180/Double.pi
                if (pos2.y > pos.y){
                    atanValue+=180
                }
                let missile3 = BossMissile(position: pos2,size: CGSize(width:75,height:20), missileId: 1, rotation: -atanValue, movementMethod: "Ghost", missileSpeed: 400.0, transparency: 0.5)
                bossMissiles.append(missile1)
                bossMissiles.append(missile2)
                bossMissiles.append(missile3)
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false){_ in
                    for index in bossMissiles.indices{
                        if (bossMissiles[index] == missile1){
                            bossMissiles[index].movementMethod = "Forward"
                            bossMissiles[index].transparency = 1
                            break
                        }
                    }
                    for index in bossMissiles.indices{
                        if (bossMissiles[index] == missile2){
                            bossMissiles[index].movementMethod = "Forward"
                            bossMissiles[index].transparency = 1
                            break
                        }
                    }
                    for index in bossMissiles.indices{
                        if (bossMissiles[index] == missile3){
                            bossMissiles[index].movementMethod = "Forward"
                            bossMissiles[index].transparency = 1
                            break
                        }
                    }
                }
            }
        }
        return 6
    }
    func runBoss3Attack1() -> CGFloat{
        let timeToRun1 = (UIScreen.main.bounds.height+bossSize.height)/600
        let timeToRun2 = (UIScreen.main.bounds.height-bossPos.y+bossSize.height/2)/600
        let timeToRun3 = timeToRun1-timeToRun2
        var time : CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            timer in
            time += delay
            bossPos.y+=600*delay
            if (time >= timeToRun2){
                timer.invalidate()
            }
        }
        for index in 0...2{
            Timer.scheduledTimer(withTimeInterval: timeToRun2 + (timeToRun1+0.5)*CGFloat(index) + 0.5, repeats: false){_ in
                time = 0
                bossPos.y = -bossSize.height/2
                bossPos.x = CGFloat.random(in:bossSize.width/2...UIScreen.main.bounds.width-bossSize.width/2)
                Timer.scheduledTimer(withTimeInterval: delay, repeats: true)
                {
                    timer in
                    time += delay
                    bossPos.y+=600*delay
                    if (time >= timeToRun1){
                        timer.invalidate()
                    }
                }
            }
        }
        Timer.scheduledTimer(withTimeInterval: timeToRun2 + (timeToRun1+0.5)*3 + 0.5, repeats: false){_ in
            time = 0
            bossPos.y = -bossSize.height/2
            bossPos.x = CGFloat.random(in:bossSize.width/2...UIScreen.main.bounds.width-bossSize.width/2)
            Timer.scheduledTimer(withTimeInterval: delay, repeats: true)
            {
                timer in
                time += delay
                bossPos.y+=600*delay
                if (time >= timeToRun3){
                    timer.invalidate()
                }
            }
        }
        return timeToRun1*4+2
    }
    func runBoss3Attack2() -> CGFloat{
        for index in 0..<3{
            Timer.scheduledTimer(withTimeInterval: CGFloat(index)*2, repeats: false){
                _ in
                let atanValue = atan(Double((pos.x-bossPos.x)/(pos.y-bossPos.y)))*180/Double.pi
                let missile = BossMissile(position: bossPos,size: CGSize(width:100,height:100), missileId: 2, rotation: -atanValue, movementMethod: "Rotating"+String(-atanValue), missileSpeed: 150.0)
                bossMissiles.append(missile)
            }
        }
        return 6.0+UIScreen.main.bounds.height/200
    }
    func runBoss3Attack3() -> CGFloat{
        for index in 0..<3{
            Timer.scheduledTimer(withTimeInterval: CGFloat(index), repeats: false){
                _ in
                let atanValue = CGFloat.random(in:-90...90)
                let missile = BossMissile(position: bossPos,size: CGSize(width:40,height:40), missileId: 1, rotation: atanValue, movementMethod: "Bouncing5", missileSpeed: 300.0)
                bossMissiles.append(missile)
            }
        }
        return 3.0+UIScreen.main.bounds.height/150
    }
    func runBoss3Attack4() -> CGFloat{
        for index in 0..<30{
            Timer.scheduledTimer(withTimeInterval: CGFloat(index)/5, repeats: false){
                _ in
                let pos = CGPoint(x:CGFloat.random(in:10...UIScreen.main.bounds.width-10),y:-37.5)
                let missile = BossMissile(position: pos,size: CGSize(width:15,height:75), missileId: 2, rotation: 0, movementMethod: "Forward", missileSpeed: 400.0)
                bossMissiles.append(missile)
            }
        }
        return 6.0+UIScreen.main.bounds.height/400
    }

    //boss health bar
    @State private var bossHealth = 50.0
    @State private var bossMaxHealth = 50.0
    var bossHealthBar: some View{
        ZStack(alignment: .leading) {
                    Rectangle()
                .frame(width: UIScreen.main.bounds.width,height: 20)
                .foregroundColor(.red)
                        .cornerRadius(10)
                    Rectangle()
                        .frame(width: bossHealth/bossMaxHealth * UIScreen.main.bounds.width, height: 20)
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
    }
    //boss missiles
    struct BossMissile: Identifiable, Equatable{
        let id = UUID()
        var position: CGPoint
        var size: CGSize = CGSize(width: 20, height: 75)
        var missileId: Int
        var rotation: CGFloat
        var movementMethod: String
        var missileSpeed: CGFloat
        var transparency: Double = 1
        static func == (lhs: BossMissile, rhs: BossMissile) -> Bool{
            return lhs.position == rhs.position && lhs.size == rhs.size && rhs.missileId == lhs.missileId && lhs.rotation == rhs.rotation && rhs.movementMethod == lhs.movementMethod && rhs.missileSpeed == lhs.missileSpeed && rhs.transparency == lhs.transparency
        }
    }
    @State private var bossMissiles:[BossMissile] = []
    func runMissileMovements(){
        for index in bossMissiles.indices.reversed() {
            if (bossMissiles[index].movementMethod == "Forward"){
                bossMissiles[index].position.y += cos(bossMissiles[index].rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                bossMissiles[index].position.x -= sin(bossMissiles[index].rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                if(bossMissiles[index].position.x < -bossMissiles[index].size.width || bossMissiles[index].position.x > UIScreen.main.bounds.width+bossMissiles[index].size.width || bossMissiles[index].position.y < -bossMissiles[index].size.height || bossMissiles[index].position.y > UIScreen.main.bounds.height+bossMissiles[index].size.height){
                    bossMissiles.remove(at: index)
                }
            }
            else if (bossMissiles[index].movementMethod.starts(with: "Bouncing")){
                bossMissiles[index].position.y += cos(bossMissiles[index].rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                bossMissiles[index].position.x -= sin(bossMissiles[index].rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                var bounce = false
                if(bossMissiles[index].position.x < bossMissiles[index].size.width/2 || bossMissiles[index].position.x > UIScreen.main.bounds.width-bossMissiles[index].size.width/2){
                    bounce = true
                    bossMissiles[index].rotation = -bossMissiles[index].rotation
                }
                if(bossMissiles[index].position.y < bossMissiles[index].size.height/2 || bossMissiles[index].position.y > UIScreen.main.bounds.height-bossMissiles[index].size.height/2){
                    bounce = true
                    bossMissiles[index].rotation = 180-bossMissiles[index].rotation
                }
                if (bounce){
                    let num = Int(bossMissiles[index].movementMethod.suffix(from: bossMissiles[index].movementMethod.index(bossMissiles[index].movementMethod.startIndex, offsetBy: 8)))
                    if (num == 1){
                        bossMissiles[index].movementMethod = "Forward"
                    }
                    else{
                        bossMissiles[index].movementMethod = "Bouncing" + String(num!-1)
                    }
                }
            }
            else if (bossMissiles[index].movementMethod.starts(with: "Rotating")){
                let string = bossMissiles[index].movementMethod.suffix(from: bossMissiles[index].movementMethod.index(bossMissiles[index].movementMethod.startIndex, offsetBy: 8))
                let rotation = Double(string)!
                bossMissiles[index].rotation += bossMissiles[index].missileSpeed * delay * 4
                bossMissiles[index].position.y += cos(rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                bossMissiles[index].position.x -= sin(rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                if(bossMissiles[index].position.x < -bossMissiles[index].size.width || bossMissiles[index].position.x > UIScreen.main.bounds.width+bossMissiles[index].size.width || bossMissiles[index].position.y < -bossMissiles[index].size.height || bossMissiles[index].position.y > UIScreen.main.bounds.height+bossMissiles[index].size.height){
                    bossMissiles.remove(at: index)
                }
            }
        }
    }
    func runMissileLoop(){
        loopingTimers.append(Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            runMissileMovements()
        })
    }
    //game
    var game: some View {
        ZStack{
            background
            bossHealthBar.position(x:UIScreen.main.bounds.width/2,y:25)
            playerHealthBar.position(x:UIScreen.main.bounds.width/2,y:UIScreen.main.bounds.height-100)
            Image("Character").resizable().frame(width:playerSize.width,height:playerSize.height).position(pos).onAppear{shoot();checkForCollisions();resetBoss()}
            ForEach(missiles){
                missile in
                Image("Missile"+missile.missileID).resizable().rotationEffect(.degrees(missile.rotation)).frame(width:missile.size.width,height:missile.size.height).position(missile.position).onAppear{}
            }
            ForEach(bossMissiles){
                missile in
                Image("BossMissile"+String(missile.missileId)).rotationEffect(.degrees(missile.rotation)).frame(width:missile.size.width,height:missile.size.height).position(missile.position).opacity(missile.transparency).onAppear{}
            }
            Image("Boss"+String(bossNum)).resizable().frame(width:bossSize.width,height:bossSize.height).position(bossPos).onAppear{runBossAttacks();runMissileLoop()}
        }
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged{
            value in
            mousePos = value.location
        }
        )
    }
    
    
    
    //upgrades
    @State var upgrades: [Int] = [0,0,0]
    @State var availableUpgrades: [Int] = [0,1,2,3]
    func resetEverything(){
        availableUpgrades = [0,1,2,3]
        availableAttacks = initialAttacks
        attacks = [Attack()]
    }
    func resetUpgrades(){
        upgrades = []
        for _ in 0..<3{
            upgrades.append(availableUpgrades[Int.random(in: availableUpgrades.indices)])
        }
    }
    var upgradeScreen: some View{
        ZStack{
            Color.white.ignoresSafeArea()
            ForEach(upgrades.indices){
                upgrade in
                configureUpgradeView(num: upgrades[upgrade],upgrade:CGFloat(upgrade))
            }
        }
    }
    func configureUpgradeView(num: Int, upgrade: CGFloat) -> some View{
        var text: String = ""
        var color: Color = Color.black
        if (num == 0){
            text = "Add +2 missiles every 4 attacks."
            color = Color.blue
        }
        if (num == 1){
            text = "Gain a spinning sword attack."
            color = Color.blue
        }
        if (num == 2){
            text = "Gain a melee sword attack."
            color = Color.blue
        }
        if (num == 3){
            text = "Occasionaly shoot out a burst in every direction."
            color = Color.blue
        }
        return Button(action: {
            configureUpgrade(num: num)
        }){
            Text(text)
                .font(.title)
                .padding()
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
        }.position(x:UIScreen.main.bounds.width/2,y:(upgrade*2+1)*UIScreen.main.bounds.height/7)
    }
    func configureUpgrade(num: Int){
        if (num == 0){
            attacks.append(availableAttacks[0])
            attacks.append(availableAttacks[1])
            availableUpgrades.remove(at: availableUpgrades.firstIndex(of: 0)!)
        }
        if (num == 1){
            attacks.append(availableAttacks[2])
            availableUpgrades.remove(at: availableUpgrades.firstIndex(of: 1)!)
        }
        if (num == 2){
            attacks.append(availableAttacks[3])
            availableUpgrades.remove(at: availableUpgrades.firstIndex(of: 2)!)
        }
        if (num == 3){
            for index in 4..<12{
                attacks.append(availableAttacks[index])
            }
            availableUpgrades.remove(at: availableUpgrades.firstIndex(of: 3)!)
        }
        for index in attacks.indices{
            attacks[index].cooldown = attacks[index].attackSpeed
        }
        upgradeScreenOpen = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
