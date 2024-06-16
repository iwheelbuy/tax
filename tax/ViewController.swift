//
//  ViewController.swift
//  tax
//
//  Created by michael.vasiliev on 06/11/2022.
//

import UIKit

struct Period: Hashable, CustomStringConvertible {
    
    let month: String
    let year: String
    
    var description: String {
        return year + "-" + month
    }
    
    static var all: [Period] {
        let months2022 = (1 ... 12).map({ Period(month: $0.month, year: "2022") })
        let months2023 = (1 ... 12).map({ Period(month: $0.month, year: "2023") })
        let months2024 = (1 ... 5).map({ Period(month: $0.month, year: "2024") })
        return months2022 + months2023 + months2024
    }
    
    static func year(_ year: String) -> [Period] {
        return (1 ... 12).map({ Period(month: $0.month, year: year) })
    }
}

extension Int {
    
    var month: String {
        "\("0\(self)".suffix(2))"
    }
}

class ViewController: UIViewController {
    
    static let mikhail = "Mikhail"
    static let iuliia = "Iuliia"
    static func extraEur(name: String) -> [Period: Double]  {
        if name == mikhail {
            return [
                .init(month: "10", year: "2022"): 564,
                .init(month: "07", year: "2022"): 333,
                .init(month: "04", year: "2022"): 257,
                .init(month: "01", year: "2023"): 60.54,
                .init(month: "04", year: "2023"): 370.94,
                .init(month: "07", year: "2023"): 500.95,
                .init(month: "10", year: "2023"): 546.40,
                .init(month: "01", year: "2024"): 756.13,
                .init(month: "04", year: "2024"): 1845.43
            ]
        } else {
            return [:]
        }
    }
    static let currencyEur = "EUR"
    static let currencyGbp = "GBP"
    static let currencyUsd = "USD"
    static let currencies = [currencyEur, currencyGbp, currencyUsd]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var revenues = [Period: Double]()
        var taxisnetTotal = [String: [Kind: Double]]()
        var taxisnet2 = [Period: [Kind: Double]]()
        var gesy = [String: [String: Double]]()
        let ibRevenuesFull = getIbRevenues(taxisnet: &taxisnetTotal)
        let ibRevenues = ibRevenuesFull.reduce(into: [Period: Double](), { result, object in
            result[object.key] = object.value[.dividends]
        })
        let exRevenuesFull = getExRevenues(taxisnet: &taxisnetTotal)
        let exRevenues = exRevenuesFull.reduce(into: [Period: Double](), { result, object in
            result[object.key] = object.value[.dividends]
        })
        for (period, revenue) in exRevenues {
            revenues[period] = (revenues[period] ?? 0) + revenue
        }
        for (period, revenue) in ibRevenues {
            revenues[period] = (revenues[period] ?? 0) + revenue
        }
        print("Exante\n\n")
        for period in Period.all {
            if let revenue = exRevenues[period], revenue != 0 {
                print("\n", period, revenue)
            }
        }
        print("\n\n\nIBKR\n\n")
        for period in Period.all {
            if let revenue = ibRevenues[period], revenue != 0 {
                print("\n", period, revenue)
            }
        }
        for year in ["2022", "2023"] {
            var revenues: Double = 0
            for period in Period.year(year) {
                if let revenue = ibRevenues[period], revenue != 0 {
                    revenues += revenue
                }
            }
            print("\n\n\nIBKR total for \(year) is \(revenues)\n\n")
        }
        for name in [Self.iuliia, Self.mikhail] {
            print("\n\n\nTotal for \(name)\n\n")
            for period in Period.all {
                let revenue = revenues[period] ?? 0
                let personRevenue = revenue * 0.5 + (Self.extraEur(name: name)[period] ?? 0)
                if personRevenue > 0 {
                    let totalTaxableAmount = Double(round(100 * personRevenue) / 100)
                    let tax = Double(round(100 * totalTaxableAmount * 0.0265) / 100)
                    print("\n", period, totalTaxableAmount, tax)
                }
            }
        }
        for name in [Self.iuliia, Self.mikhail] {
            print("\n\n\nTaxisnet for \(name)\n\n")
            var taxisnet = [String: [Kind: Double]]()
            for year in taxisnetTotal.keys {
                let total = taxisnetTotal[year] ?? [:]
                taxisnet[year] = total.reduce(into: [Kind: Double](), { result, value in
                    result[value.key] = value.value / 2
                })
            }
            for period in Period.all {
                let extra = Self.extraEur(name: name)[period] ?? 0
                var total = taxisnet[period.year] ?? [:]
                total[.dividends] = (total[.dividends] ?? 0) + extra
                taxisnet[period.year] = total
            }
            for (year, values) in taxisnet.sorted(by: { $0.key.description < $1.key.description }) {
                for validYear in ["2022", "2023"] where validYear == year {
                    print("\nYEAR: \(year)")
                    for (kind, value) in values.sorted(by: { $0.key.description < $1.key.description }) {
                        switch kind {
                        case .dividends:
                            print("DIV: ", pretty(value))
                        case .withholdingTax:
                            print("TAX: ", pretty(value * -1))
                        }
                    }
                }
            }
        }
    }
    
    func pretty(_ value: Double) -> String {
        return formatter.string(from: NSNumber.init(floatLiteral: value))!
    }
    
    var formatter: NumberFormatter = {
        let result = NumberFormatter()
        result.numberStyle = .decimal
        result.usesGroupingSeparator = false
        result.minimumIntegerDigits = 1
        result.maximumFractionDigits = 2
        result.minimumFractionDigits = 2
        return result
    }()
    
    func getRevenues(getEvent: (String, String) -> (event: Event, value: Value)?, lines: [[String]], taxisnet: inout [String: [Kind: Double]]) -> [Period: [Kind: Double]] {
        let events = getEvents(getEvent: getEvent, lines: lines)
        let eventsSorted = events.sorted(by: {
            if $0.key.date < $1.key.date {
                return true
            } else if $0.key.date > $1.key.date {
                return false
            } else {
                return $0.key.name < $1.key.name
            }
        })
        var revenues = [Period: [Kind: Double]]()
        for (event, values) in eventsSorted {
            let nice = values.sorted(by: { lhs, rhs in
                if lhs.key == .dividends {
                    return true
                }
                return false
            }).map({ $0.value })
            if event.name != "None" {
                assert(nice[0] > 0)
                if nice.count > 1 {
                    assert(nice[1] < 0)
                }
            }
            let dividends = values.reduce(into: 0, { result, value in
                switch value.key {
                case .dividends:
                    result += value.value
                case .withholdingTax:
                    result += 0
                }
            })
            let withholdingTax = values.reduce(into: 0, { result, value in
                switch value.key {
                case .dividends:
                    result += 0
                case .withholdingTax:
                    result += value.value
                }
            })
            let dividendsToEur = dividends / toEur(event: event)
            let withholdingTaxToEur = withholdingTax / toEur(event: event)
            var revenuesForPeriod = revenues[event.period] ?? [.dividends: 0, .withholdingTax: 0]
            revenuesForPeriod[.dividends] = revenuesForPeriod[.dividends]! + dividendsToEur
            revenuesForPeriod[.withholdingTax] = revenuesForPeriod[.withholdingTax]! + withholdingTaxToEur
            revenues[event.period] = revenuesForPeriod
        }
        for (period, values) in revenues {
            var taxisnetYear = taxisnet[period.year] ?? [:]
            for (kind, value) in values {
                taxisnetYear[kind] = (taxisnetYear[kind] ?? 0) + value
            }
            taxisnet[period.year] = taxisnetYear
        }
        return revenues
    }
    
    func getEvents2(getEvent: (String, String) -> (event: Event, value: Value)?, lines: [[String]]) -> [Event: [(Kind, Double)]] {
        let result0: [Set<String>] = lines
            .reduce(into: [Set<String>](), { array, lines in
                var result = Set<String>()
                for line in lines {
                    for currency in Self.currencies {
                        if getEvent(line, currency) != nil {
                            if result.insert(line).inserted == false {
                                fatalError("Не должно быть идентичных событий в одном массиве: \(line)")
                            }
                        }
                    }
                }
                array += [result]
            })
        let result1: Set<String> = result0
            .reduce(Set<String>(), { $0.union($1) })
        let result2: [Event: [(Kind, Double)]] = result1
            .reduce(into: [Event: [(Kind, Double)]](), { result, line in
                for currency in Self.currencies {
                    if let (event, value) = getEvent(line, currency) {
                        var array = result[event] ?? []
                        array.append((value.kind, value.value))
                        result[event] = array
                    }
                }
            })
        return result2
    }
    
    func getEvents(getEvent: (String, String) -> (event: Event, value: Value)?, lines: [[String]]) -> [Event: [Kind: Double]] {
        return getEvents2(getEvent: getEvent, lines: lines)
            .reduce(into: [Event: [Kind: Double]]()) { result, object in
                let event: Event = object.key
                let array: [(Kind, Double)] = object.value
                var dict = [Kind: Double]()
                for (kind, value) in array {
                    let prev = dict[kind] ?? 0
                    dict[kind] = prev + value
                }
                result[event] = dict
            }
    }
    
    func getLines(_ name: String) -> [String] {
        let url = Bundle.main.url(forResource: name.components(separatedBy: ".")[0], withExtension: name.components(separatedBy: ".")[1])!
        let string = try! String(contentsOf: url, encoding: .utf8)
        return string.components(separatedBy: "\n")
    }
    
    func getExRevenues(taxisnet: inout [String: [Kind: Double]]) -> [Period: [Kind: Double]] {
        return getRevenues(
            getEvent: getExEvent,
            lines: [
                getLines("ex.txt")
            ],
            taxisnet: &taxisnet
        )
    }
    
    func getIbRevenues(taxisnet: inout [String: [Kind: Double]]) -> [Period: [Kind: Double]] {
        return getRevenues(
            getEvent: getIbEvent,
            lines: [
                getLines("U8508545_20221229_20230501.csv"),
                getLines("U8508545_20230102_20230303.csv"),
                getLines("U8508545_20220228_20230228.csv"),
                getLines("U8508545_20221230_20230407.csv"),
                getLines("U8508545_20220609_20230609.csv"),
                getLines("U8508545_20220718_20230717.csv"),
                getLines("U8508545_20220809_20230809.csv"),
                getLines("U8508545_20220915_20230915.csv"),
                getLines("U8508545_20221219_20231218.csv"),
                getLines("U8508545_20230202_20240202.csv"),
                getLines("U8508545_20230601_20240531.csv"),
                getLines("U8508545_20230615_20240614.csv"),
                getLines("ib2022.csv")
            ],
            taxisnet: &taxisnet
        )
    }
    
    func toEur(event: Event) -> Double {
        if event.currency == Self.currencyEur {
            return 1
        } else if event.currency == Self.currencyUsd {
            switch event.dateEcb {
            case "21/03/2022":
                return 1.1038
            case "22/03/2022":
                return 1.1024
            case "23/03/2022":
                return 1.0985
            case "24/03/2022":
                return 1.0978
            case "25/03/2022":
                return 1.1002
            case "01/04/2022":
                return 1.1052
            case "25/04/2022":
                return 1.0746
            case "24/05/2022":
                return 1.0720
            case "27/05/2022":
                return 1.0722
            case "09/06/2022":
                return 1.0743
            case "15/06/2022":
                return 1.0431
            case "17/06/2022":
                return 1.0486
            case "21/06/2022":
                return 1.0550
            case "22/06/2022":
                return 1.0521
            case "23/06/2022":
                return 1.0493
            case "24/06/2022":
                return 1.0524
            case "27/06/2022":
                return 1.0572
            case "28/06/2022":
                return 1.0561
            case "29/06/2022":
                return 1.0517
            case "30/06/2022":
                return 1.0387
            case "01/07/2022":
                return 1.0425
            case "27/07/2022":
                return 1.0152
            case "28/07/2022":
                return 1.0122
            case "04/08/2022":
                return 1.0181
            case "30/08/2022":
                return 1.0034
            case "22/09/2022":
                return 0.9884
            case "23/09/2022":
                return 0.9754
            case "28/09/2022":
                return 0.9565
            case "29/09/2022":
                return 0.9706
            case "30/09/2022":
                return 0.9748
            case "28/10/2022":
                return 0.9951
            case "29/11/2022":
                return 1.0366
            case "12/12/2022":
                return 1.0562
            case "19/12/2022":
                return 1.0598
            case "20/12/2022":
                return 1.0599
            case "22/12/2022":
                return 1.0633
            case "23/12/2022":
                return 1.0622
            case "28/12/2022":
                return 1.0640
            case "29/12/2022":
                return 1.0649
            case "30/12/2022":
                return 1.0666
            case "06/01/2023":
                return 1.0500
            case "25/01/2023":
                return 1.0878
            case "30/01/2023":
                return 1.0903
            case "27/02/2023":
                return 1.0554
            case "23/03/2023":
                return 1.0879
            case "24/03/2023":
                return 1.0745
            case "28/03/2023":
                return 1.0841
            case "29/03/2023":
                return 1.0847
            case "30/03/2023":
                return 1.0886
            case "27/04/2023":
                return 1.1042
            case "30/05/2023":
                return 1.0744
            case "13/06/2023":
                return 1.0793
            case "23/06/2023":
                return 1.0884
            case "26/06/2023":
                return 1.0918
            case "27/06/2023":
                return 1.0951
            case "28/06/2023":
                return 1.0938
            case "29/06/2023":
                return 1.0938
            case "06/07/2023":
                return 1.0899
            case "26/07/2023":
                return 1.1059
            case "28/07/2023":
                return 1.1010
            case "30/08/2023":
                return 1.0886
            case "21/09/2023":
                return 1.0635
            case "22/09/2023":
                return 1.0647
            case "26/09/2023":
                return 1.0605
            case "27/09/2023":
                return 1.0536
            case "28/09/2023":
                return 1.0539
            case "02/10/2023":
                return 1.0530
            case "30/10/2023":
                return 1.0605
            case "29/11/2023":
                return 1.0985
            case "11/12/2023":
                return 1.0757
            case "15/12/2023":
                return 1.0946
            case "21/12/2023":
                return 1.0983
            case "22/12/2023":
                return 1.1023
            case "27/12/2023":
                return 1.1065
            case "28/12/2023":
                return 1.1114
            case "29/12/2023":
                return 1.1050
            case "03/01/2024":
                return 1.0919
            case "05/01/2024":
                return 1.0921
            case "24/01/2024":
                return 1.0905
            case "30/01/2024":
                return 1.0846
            case "28/02/2024":
                return 1.0808
            case "20/03/2024":
                return 1.0844
            case "21/03/2024":
                return 1.0907
            case "22/03/2024":
                return 1.0823
            case "26/03/2024":
                return 1.0855
            case "27/03/2024":
                return 1.0816
            case "29/04/2024":
                return 1.0720
            case "30/05/2024":
                return 1.0815
            default:
                // https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-usd.en.html
                fatalError()
            }
        } else if event.currency == Self.currencyGbp {
            switch event.dateEcb {
            case "09/12/2022":
                return 0.85950
            case "15/12/2023":
                return 0.85833
            default:
                // https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-gbp.en.html
                fatalError()
            }
        } else {
            fatalError()
        }
    }
    
    func getExEvent(line: String, currency: String) -> (event: Event, value: Value)? {
        let components = line.components(separatedBy: "\t").map({ $0.replacingOccurrences(of: "\"", with: "") })
        guard components.count > 6 else {
            return nil
        }
        guard currency == components[7] else {
            return nil
        }
        let valueMaker: (Double) -> Value
        if components[4] == "TAX" {
            valueMaker = { (.withholdingTax, $0) }
        } else if components[4] == "DIVIDEND" {
            valueMaker = { (.dividends, $0) }
        } else {
            return nil
        }
        let date = components[5].components(separatedBy: " ")[0]
        let name = components[2]
        let event = Event(currency: currency, date: date, name: name)
        let value = Double(components[6])!
        return (event, valueMaker(value))
    }
    
    func getIbEvent(line: String, currency: String) -> (event: Event, value: Value)? {
        let prefix: String
        let dividendsPrefix = "Dividends,Data,\(currency),"
        let withholdingTaxPrefix = "Withholding Tax,Data,\(currency),"
        let valueMaker: (Double) -> Value
        if line.hasPrefix(dividendsPrefix) {
            prefix = dividendsPrefix
            valueMaker = { (.dividends, $0) }
        } else if line.hasPrefix(withholdingTaxPrefix) {
            prefix = withholdingTaxPrefix
            valueMaker = { (.withholdingTax, $0) }
        } else {
            return nil
        }
        let components = line
            .replacingOccurrences(of: prefix, with: "")
            .components(separatedBy: ",")
            .filter({ $0.isEmpty == false })
        let date = components[0]
        let name = components[1].components(separatedBy: " ")[0]
        let event = Event(currency: currency, date: date, name: name)
        let value = Double(components[2])!
        return (event, valueMaker(value))
    }
}

struct Event: Hashable {
    
    let currency: String
    let date: String
    let name: String
    
    var dateEcb: String {
        return date.components(separatedBy: "-").reversed().joined(separator: "/")
    }
    
    var period: Period {
        let month = date.components(separatedBy: "-")[1]
        return .init(month: month, year: year)
    }
    
    var year: String {
        return date.components(separatedBy: "-")[0]
    }
}

typealias Value = (kind: Kind, value: Double)

enum Kind: String, CustomStringConvertible {
    
    case dividends
    case withholdingTax
    
    var description: String {
        switch self {
        case .dividends:
            return "DIV"
        case .withholdingTax:
            return "TAX"
        }
    }
}
