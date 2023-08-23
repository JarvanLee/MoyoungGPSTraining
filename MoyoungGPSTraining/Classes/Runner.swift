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

/// 目标类型
public enum RunGoalType {
    case none
    // 单位米
    case distance(goal: Double)
    // 单位秒
    case time(goal: TimeInterval)
    // 配速
    case pace(goal: Double)
    // 卡路里
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
    
    /// 计算实时数据时，秒数间隔，默认是10
    public var realTimeInterval: TimeInterval = 10
    
    deinit {
        self.stop()
        print("\(Self.self) \(#function)")
    }
    
    private var run = Run()
    
    private var provider: BaseProvider?
    
    private var timer: Timer?
    
    private var lastMinSteps = 0
    private var lastMinDistance = 0.0
    private var currentHearts: [Int] = []
    private let goalProgress = Progress()
    private var altitudeArray: [Double] = []
    private var lastSecondDistance = 0.0
    
    private var totalTime: TimeInterval {
        return run.totalValidDuration
    }

    private var totalMeters: Measurement<UnitLength> {
        return Measurement(value: run.totalDistance, unit: UnitLength.meters)
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
        // 这个瞬时速度暂时没用
        provider.speedHandler = { [weak self] value in
            guard value >= 0 else { return }
            self?.run.currentSpeed = value
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
        provider.trainingLineHandler = { [weak self] value in
            guard let `self` = self else { return }
            self.delegate?.runner(self, didUpdateTimeLine: value)
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
        guard runState != .running else { return }
        runState = .running
        provider?.start()
        
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerRun), userInfo: nil, repeats: true)
        }
    }
    
    func pause() {
        guard runState != .pause else { return }
        runState = .pause
        provider?.pause()
    }
    
    func stop() {
        guard runState != .stop else { return }
        runState = .stop
        provider?.stop()
        
        timer?.invalidate()
        timer = nil
        
        calculateMinuteData()
        calculateTimePerKilometreAndMile()
        calculateRealTimeData()
        stopedCalculate()
        delegate?.runner(self, didUpdateRun: run)
    }
}

// MARK: - 自定义私有方法

extension Runner {
    /// 计时器
    @objc private func timerRun() {
        if Int(Date().timeIntervalSince1970) % 60 == 0 {
            calculateMinuteData()
        }
        
        switch runState {
        case .running:
            run.totalValidDuration += 1
            calculateGoalProgress()
            calculateTimePerKilometreAndMile()
            calculateRealTimeData()
            delegate?.runner(self, didUpdateRun: run)
        default:
            break
        }
    }
    
    /// 计算每分钟数据（每分钟步数、每分钟距离）
    private func calculateMinuteData() {
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
    
    /// 计算目标进度
    private func calculateGoalProgress() {
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
    
    /// 计算每公里和每英里耗时
    private func calculateTimePerKilometreAndMile() {
        /// 有新的一公里，添加时间
        // 计算公里
        do {
            var timeArray = run.timeForKilometer
            let totalKm = totalMeters.converted(to: UnitLength.kilometers)
            if Int(totalKm.value) == timeArray.count + 1 {
                var newTime = totalTime - timeArray.reduce(0, +)
                let newDistance = totalKm - Measurement(value: Double(timeArray.count), unit: UnitLength.kilometers)
                if newDistance.value > 1 {
                    let delta = Double(newTime) / newDistance.value * (newDistance.value - 1)
                    newTime -= delta
                }
                timeArray.append(newTime)
                run.timeForKilometer = timeArray
            } else {
                if runState == .stop {
                    let newTime = totalTime - timeArray.reduce(0, +)
                    timeArray.append(newTime)
                    run.timeForKilometer = timeArray
                }
            }
        }
        
        // 计算英里
        do {
            var timeArray = run.timeForMile
            let totalMile = totalMeters.converted(to: UnitLength.miles)
            if Int(totalMile.value) == timeArray.count + 1 {
                var newTime = totalTime - timeArray.reduce(0, +)
                let newDistance = totalMile - Measurement(value: Double(timeArray.count), unit: UnitLength.miles)
                if newDistance.value > 1 {
                    let delta = Double(newTime) / newDistance.value * (newDistance.value - 1)
                    newTime -= delta
                }
                timeArray.append(newTime)
                run.timeForMile = timeArray
            } else {
                if runState == .stop {
                    let newTime = totalTime - timeArray.reduce(0, +)
                    timeArray.append(newTime)
                    run.timeForMile = timeArray
                }
            }
        }
    }
    
    /// 计算实时数据（每10秒一个数据）
    /// 目前有实时配速、实时海拔
    private func calculateRealTimeData() {
        let lastSecond = Int(run.totalValidDuration) % Int(self.realTimeInterval)
        if lastSecond == 0 || (lastSecond != 0 && runState == .stop) {
            // 计算实时配速
            let distance = run.totalDistance - lastSecondDistance
            if distance <= 0 {
                run.realTimeSpeed.append(-1.0)
            } else {
                let pace = (lastSecond == 0 ? self.realTimeInterval : Double(lastSecond)) / distance
                run.realTimeSpeed.append(pace)
            }
            lastSecondDistance = run.totalDistance
            
            // 计算实时海拔
            if let last = altitudeArray.last {
                run.realTimeElevation.append(last)
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
        self.lastSecondDistance = 0
    }
}
