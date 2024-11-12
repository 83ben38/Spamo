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
            }
            else if missiles[index].position.y > -100 {
                missiles[index].position.y -= missileSpeed * delay
            } else {
                missiles.remove(at: index)
            }
        }
    }
    
    //bosses
    @State private var bossNum = 1
    @State private var bossPos: CGPoint = CGPoint(x:UIScreen.main.bounds.width/2,y:100)
    @State private var bossSize = CGSize(width:150,height:65)
    func resetBoss(){
        bossPos = CGPoint(x:UIScreen.main.bounds.width/2,y:100)
        if (bossNum == 1){
            bossSize = CGSize(width:150,height:65)
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
            let bossAttackNum = CGFloat.random(in: 1...1)
            if (bossAttackNum == 1){
                return runBoss1Attack1()
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
    }
    @State private var bossMissiles:[BossMissile] = []
    func runMissileMovements(){
        for index in bossMissiles.indices.reversed() {
            if (bossMissiles[index].movementMethod == "Forward"){
                bossMissiles[index].position.y += cos(bossMissiles[index].rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
                bossMissiles[index].position.x -= sin(bossMissiles[index].rotation * CGFloat.pi / 180) * bossMissiles[index].missileSpeed * delay
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
            bossHealthBar.position(x:UIScreen.main.bounds.width/2,y:50)
            playerHealthBar.position(x:UIScreen.main.bounds.width/2,y:UIScreen.main.bounds.height-100)
            Image("Character").resizable().frame(width:playerSize.width,height:playerSize.height).position(pos).onAppear{shoot();checkForCollisions()}
            ForEach(missiles){
                missile in
                Image("missile").resizable().rotationEffect(.degrees(missile.rotation)).frame(width:missile.size.width,height:missile.size.height).position(missile.position).onAppear{}
            }
            ForEach(bossMissiles){
                missile in
                Image("BossMissile"+String(missile.missileId)).rotationEffect(.degrees(missile.rotation)).frame(width:missile.size.width,height:missile.size.height).position(missile.position).onAppear{}
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
