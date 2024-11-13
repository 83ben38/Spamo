//
//  ContentView.swift
//  Spamo
//
//  Created by Ben Blodgett on 11/9/24.
//

import SwiftUI
struct ContentView: View {
    @State private var gameStarted = false
    var body: some View{
        ZStack{
            if (gameStarted){
                game
            }
            else{
                background
                titleScreen
            }
        }
    }
    
    //title screen
    var titleScreen: some View{
        VStack {
            Text("Spamo")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()

            Button(action: {
            // Start the game by changing the state variable
                gameStarted = true
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
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            pos = CGPoint(x:(3*pos.x+mousePos.x)/4,y:(3*pos.y+mousePos.y)/4)
        }
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            damageCooldown -= delay;
            if (damageCooldown <= 0.0){
                let playerRect = CGRect(origin: pos, size: playerSize).offsetBy(dx: -playerSize.width/2, dy: -playerSize.height/2)
                let bossRect = CGRect(origin: bossPos, size: bossSize).offsetBy(dx: -bossSize.width/2, dy: -bossSize.height/2)
                if playerRect.intersects(bossRect){
                    playerHealth-=1;
                    if (playerHealth == 0.0){
                        gameStarted = false;
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
                                gameStarted = false;
                            }
                            damageCooldown = 1.0
                            bossMissiles.remove(at: bossMissiles.firstIndex(of:missile)!)
                            return
                        }
                    }
                }
            }
        }
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
    }
    @State private var missiles:[Missile] = []
    private let attackSpeed = 1.0
    private let missileSpeed = 400.0
    private let missileDamage = 1.0;
    func shoot(){
        Timer.scheduledTimer(withTimeInterval: attackSpeed, repeats: true) { _ in
            missiles.append(Missile(position: pos))
        }
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            updateMissilePositions()
        }
    }
    private let delay = 0.02;
    func updateMissilePositions(){
        let bossRect = CGRect(origin: bossPos, size: bossSize).offsetBy(dx: -bossSize.width/2, dy: -bossSize.height/2)
        for index in missiles.indices.reversed() {
            let missileRect = CGRect(origin: missiles[index].position, size: missiles[index].size).offsetBy(dx: -missiles[index].size.width/2, dy: -missiles[index].size.height/2)
            if (missileRect.intersects(bossRect)){
                missiles.remove(at: index)
                bossHealth-=missileDamage
                if (bossHealth <= 0){
                    bossNum+=1;
                    resetBoss()
                }
            }
            else if missiles[index].position.y > -100 {
                missiles[index].position.y -= missileSpeed * delay
            } else {
                missiles.remove(at: index)
            }
        }
    }
    
    //bosses
    @State private var bossNum = 2
    @State private var bossPos: CGPoint = CGPoint(x:UIScreen.main.bounds.width/2,y:100)
    @State private var bossSize = CGSize(width:150,height:65)
    func resetBoss(){
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
    }
    //boss attacks
    private let attackCooldown = 2.0
    func runBossAttacks(){
        Timer.scheduledTimer(withTimeInterval: attackCooldown, repeats: false){
            _ in
            let timeToRun = runBossAttack()
            Timer.scheduledTimer(withTimeInterval: timeToRun, repeats: false){
                _ in
                if (gameStarted){
                    runBossAttacks()
                }
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
            let bossAttackNum = Int.random(in: 3...3)
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
            Timer.scheduledTimer(withTimeInterval: CGFloat(index), repeats: false){
                _ in
                let atanValue = atan(Double((pos.x-bossPos.x)/(pos.y-bossPos.y)))*180/Double.pi
                let missile = BossMissile(position: bossPos,size: CGSize(width:75,height:20), missileId: 1, rotation: -atanValue, movementMethod: "Bouncing"+String(3-index), missileSpeed: 300.0)
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
        }
    }
    func runMissileLoop(){
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true){
            _ in
            runMissileMovements()
        }
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
                Image("missile").resizable().rotationEffect(.degrees(missile.rotation)).frame(width:missile.size.width,height:missile.size.height).position(missile.position).onAppear{}
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
