//
//  Runner.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/8.
//

import CoreLocation
import Foundation

public enum RunState {
    case running
    case pause
    case stop
}

public enum RunGoalType {
    case none
    // 单位米
    case distance(goal: Double)
    // 单位秒
    case time(goal: TimeInterval)
    
    case pace(goal: Double)
    case calorise(goal: Int)
}

open class Runner: NSObject {
    public weak var delegate: RunnerDelegate?
    
    public var goal: RunGoalType = .none {
        didSet {
            switch goal {
            case .none:
                break
            case .distance(let goal):
                goalProgress.totalUnitCount = Int64(goal)
            case .time(let goal):
                goalProgress.totalUnitCount = Int64(goal)
            case .pace(let goal):
                goalProgress.totalUnitCount = Int64(goal)
            case .calorise(let goal):
                goalProgress.totalUnitCount = Int64(goal)
            }
        }
    }
    
    public private(set) var runState: RunState = .stop {
        didSet {
            delegate?.runner(self, didUpdateState: runState)
        }
    }
    
    private var run = Run()
    
    private var provider: BaseProvider?
    
    private var timer: Timer?
    
    private var lastMinSteps = 0
    private var lastMinDistance = 0.0
    private var currentHearts: [Int] = []
    private let goalProgress = Progress()
    private var altitudeArray: [Double] = []
    private var speedArray: [TimeInterval] = []
    private var realTimeSpeedArray: [Double] = []
    
    private var totalTime: TimeInterval {
        return run.totalValidDuration
    }

    private var totalDistance: Double {
        return run.totalDistance
    }
    
    override public init() {
        super.init()
    }
}

// MARK: - 对外方法

public extension Runner {
    func setProvider(_ provider: BaseProvider) {
        self.provider = provider

        provider.stepsHandler = { [weak self] value in
            self?.run.totalStep = value
        }
        provider.distanceHandler = { [weak self] value in
            self?.run.totalDistance = value
        }
        provider.calorieHandler = { [weak self] value in
            self?.run.totalCalorie = value
        }
        provider.speedHandler = { [weak self] value in
            self?.run.currentSpeed = value
            self?.realTimeSpeedArray.append(value)
        }
        provider.heartHandler = { [weak self] value in
            guard let `self` = self else { return }
            guard value > 0, value < 255 else {
                return
            }
            self.run.currentHeart = value
            self.run.maxHeart = max(value, self.run.maxHeart ?? 0)
            self.run.minHeart = min(value, self.run.minHeart ?? 255)
            self.currentHearts.append(value)
        }
        provider.altitudeListHandler = { [weak self] value in
            guard let `self` = self else { return }
            self.altitudeArray = value
        }
        provider.locationsHander = { [weak self] value in
            guard let `self` = self else { return }
            self.delegate?.runner(self, didUpdateLocations: value)
        }
        provider.locationSingleHandler = { [weak self] value in
            guard let `self` = self else { return }
            self.delegate?.runner(self, didUpdateSignalLevel: value)
        }
        provider.headingAngleHandler = { [weak self] value in
            guard let `self` = self else { return }
            self.delegate?.runner(self, didUpdateHeadingAngle: value)
        }
        provider.authorizationStatusHandler = { [weak self] value in
            guard let `self` = self else { return }
            self.delegate?.runner(self, didChangeAuthorization: value)
        }
        provider.locationFailHandler = { [weak self] value in
            guard let `self` = self else { return }
            self.delegate?.runner(self, didFailWithError: value)
        }
    }
    
    
    func start() {
        if runState == .stop {
            reset()
        }
        runState = .running
        provider?.start()
        
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerRun), userInfo: nil, repeats: true)
        }
    }
    
    func pause() {
        runState = .pause
        provider?.pause()
    }
    
    func stop() {
        runState = .stop
        provider?.stop()
        
        timer?.invalidate()
        timer = nil
        
        dealMinuteData()
        calculateTimePerKilometre()
        calculateReatTimeElevation()
        stopedCalculate()
        delegate?.runner(self, didUpdateRun: run)
    }
}

// MARK: - 自定义私有方法

extension Runner {
    /// 计时器
    @objc private func timerRun() {
        if Int(Date().timeIntervalSince1970) % 60 == 0 {
            dealMinuteData()
        }
        
        switch runState {
        case .running:
            run.totalValidDuration += 1
            dealGoalProgress()
            calculateTimePerKilometre()
            calculateReatTimeElevation()
            delegate?.runner(self, didUpdateRun: run)
        default:
            break
        }
    }
    
    /// 处理每分钟数据
    private func dealMinuteData() {
        let pastMinSteps = run.totalStep - lastMinSteps
        run.stepsPerMinute.append(Int(pastMinSteps))
        
        let pastMinDistance = run.totalDistance - lastMinDistance
        run.distancePerMinute.append(pastMinDistance)
        
        let hearts = currentHearts.filter { $0 > 0 && $0 < 255 }
        if hearts.count > 0 {
            run.heartPerMinute.append(hearts.reduce(0) { $0 + $1 } / hearts.count)
        }
        
        lastMinSteps = run.totalStep
        lastMinDistance = run.totalDistance
        currentHearts = []
    }
    
    /// 处理目标进度
    private func dealGoalProgress() {
        switch goal {
        case .time:
            goalProgress.completedUnitCount = Int64(run.totalValidDuration)
        case .distance:
            goalProgress.completedUnitCount = Int64(run.totalDistance)
        case .calorise:
            goalProgress.completedUnitCount = Int64(run.totalCalorie)
        case .pace(let goal):
            var vprogress: Double = 0
            let speed = run.getAverageSpeed
            if speed > 0 {
                vprogress = abs(goal - speed) / (goal * 2)
                if speed < goal {
                    vprogress += 0.5
                } else {
                    vprogress = 0.5 - vprogress
                    if vprogress < 0 {
                        vprogress = 0
                    }
                }
            }
            goalProgress.completedUnitCount = Int64(vprogress)
        default:
            break
        }
        delegate?.runner(self, didUpdateGoalProgress: goalProgress)
    }
    
    /// 计算每公里耗时
    private func calculateTimePerKilometre() {
        // 有新的一公里，添加时间
        if Int(totalDistance) == speedArray.count + 1 {
            let lastTime = speedArray.reduce(0, +)
            var newTime = totalTime - lastTime
            let lastDistance = Double(speedArray.count)
            let newDistance = totalDistance - lastDistance
            if newDistance > 1 {
                let delta = Double(newTime) / (totalDistance - lastDistance) * (totalDistance - lastDistance - 1)
                newTime -= delta
            }
            speedArray.append(newTime)
            run.timeForKilometer = speedArray
        } else {
            if runState == .stop {
                let lastTime = totalTime - speedArray.reduce(0, +)
                speedArray.append(lastTime)
                run.timeForKilometer = speedArray
            }
        }
    }
    
    /// 计算实时海拔(每10秒一个数据)
    private func calculateReatTimeElevation() {
        if Int(run.totalValidDuration) % 10 == 0 || runState == .stop {
            if let last = altitudeArray.last {
                run.realTimeElevation.append(last)
            }
            if let last = realTimeSpeedArray.last {
                run.realTimeSpeed.append(last)
            }
        }
    }
    
    /// 运动结束时需要计算的一些数据
    private func stopedCalculate() {
        run.climbingHeight = provider?.calculateElevation() ?? 0.0
    }
    
    private func reset() {
        self.run = Run()
        self.lastMinSteps = 0
        self.lastMinDistance = 0
        self.currentHearts = []
        self.goalProgress.completedUnitCount = 0
        self.altitudeArray = []
        self.speedArray = []
        self.realTimeSpeedArray = []
    }
}
