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
        let months2023 = (1 ... 4).map({ Period(month: $0.month, year: "2023") })
        return months2022 + months2023
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
    static func extraEur(name: String) -> [Period: Double]  {
        if name == mikhail {
            return [
                .init(month: "10", year: "2022"): 564,
                .init(month: "07", year: "2022"): 333,
                .init(month: "04", year: "2022"): 257,
                .init(month: "01", year: "2023"): 60.54,
                .init(month: "04", year: "2023"): 370.94
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
        let ibRevenues = getIbRevenues()
        let exRevenues = getExRevenues()
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
        for year in ["2022"] {
            var revenues: Double = 0
            for period in Period.year(year) {
                if let revenue = ibRevenues[period], revenue != 0 {
                    revenues += revenue
                }
            }
            print("\n\n\nIBKR total for \(year) is \(revenues)\n\n")
        }
        for name in ["Iuliia", Self.mikhail] {
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
    }
    
    func getRevenues(getEvent: (String, String) -> (event: Event, value: Double)?, lines: [[String]]) -> [Period: Double] {
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
        var revenues = [Period: Double]()
        for (event, values) in eventsSorted {
            let received = values.reduce(0, +)
            let revenue = received / toEur(event: event)
            revenues[event.period] = (revenues[event.period] ?? 0) + revenue
        }
        return revenues
    }
    
    func getEvents(getEvent: (String, String) -> (event: Event, value: Double)?, lines: [[String]]) -> [Event: [Double]] {
        return lines
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
            .reduce(Set<String>(), { $0.union($1) })
            .reduce(into: [Event: [Double]](), { result, line in
                for currency in Self.currencies {
                    if let (event, value) = getEvent(line, currency) {
                        if let values = result[event] {
                            result[event] = (values + [value]).sorted(by: >)
                        } else {
                            result[event] = [value]
                        }
                    }
                }
            })
    }
    
    func getLines(_ name: String) -> [String] {
        let url = Bundle.main.url(forResource: name.components(separatedBy: ".")[0], withExtension: name.components(separatedBy: ".")[1])!
        let string = try! String(contentsOf: url, encoding: .utf8)
        return string.components(separatedBy: "\n")
    }
    
    func getExRevenues() -> [Period: Double] {
        return getRevenues(
            getEvent: getExEvent,
            lines: [
                getLines("ex.txt")
            ]
        )
    }
    
    func getIbRevenues() -> [Period: Double] {
        return getRevenues(
            getEvent: getIbEvent,
            lines: [
                getLines("U8508545_20221229_20230501.csv"),
                getLines("U8508545_20230102_20230303.csv"),
                getLines("U8508545_20220228_20230228.csv"),
                getLines("U8508545_20221230_20230407.csv")
            ]
        )
    }
    
    func toEur(event: Event) -> Double {
        if event.currency == Self.currencyEur {
            return 1
        } else if event.currency == Self.currencyUsd {
            // https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-usd.en.html
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
            default:
                fatalError()
            }
        } else if event.currency == Self.currencyGbp {
            // https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-gbp.en.html
            switch event.dateEcb {
            case "09/12/2022":
                return 0.85950
            default:
                fatalError()
            }
        } else {
            fatalError()
        }
    }
    
    func getExEvent(line: String, currency: String) -> (event: Event, value: Double)? {
        let components = line.components(separatedBy: "\t").map({ $0.replacingOccurrences(of: "\"", with: "") })
        guard components.count > 6 else {
            return nil
        }
        guard currency == components[7] else {
            return nil
        }
        let valueMultiplier: Double
        if components[4] == "TAX" {
            valueMultiplier = -1
        } else if components[4] == "DIVIDEND" {
            valueMultiplier = 1
        } else {
            return nil
        }
        let date = components[5].components(separatedBy: " ")[0]
        let name = components[2]
        let event = Event(currency: currency, date: date, name: name)
        let value = abs(Double(components[6])!)
        return (event, value * valueMultiplier)
    }
        
    func getIbEvent(line: String, currency: String) -> (event: Event, value: Double)? {
        let prefix: String
        let dividendsPrefix = "Dividends,Data,\(currency),"
        let withholdingTaxPrefix = "Withholding Tax,Data,\(currency),"
        if line.hasPrefix(dividendsPrefix) {
            prefix = dividendsPrefix
        } else if line.hasPrefix(withholdingTaxPrefix) {
            prefix = withholdingTaxPrefix
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
        return (event, value)
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
        let year = date.components(separatedBy: "-")[0]
        let month = date.components(separatedBy: "-")[1]
        return .init(month: month, year: year)
    }
}
