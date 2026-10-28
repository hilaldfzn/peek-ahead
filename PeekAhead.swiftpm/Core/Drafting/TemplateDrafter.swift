import Foundation

/// Drafts a story from built-in templates. Always available, offline, and deterministic: the fallback whenever the
/// on-device model is unavailable or declines.
///
/// A few keywords in the grown-up's details add pages, for example fireworks or a loud room. Template wording is a
/// placeholder until the expert review, like every bundled story.
struct TemplateDrafter: StoryDrafting {
    private let makeID: @Sendable () -> String

    init(makeID: @escaping @Sendable () -> String = { "story-\(UUID().uuidString.lowercased())" }) {
        self.makeID = makeID
    }

    func draft(_ request: DraftRequest) async throws -> Story {
        makeStory(request)
    }

    /// The synchronous core of `draft`, also used by tests.
    func makeStory(_ request: DraftRequest) -> Story {
        let template = Templates.template(for: request.event, language: request.language)
        let details = request.details.lowercased()
        var lines = template.opening
        var sounds = template.sounds
        var tools = template.calmTools
        for extra in template.extras where extra.keywords.contains(where: { details.contains($0) }) {
            lines.append(contentsOf: extra.lines)
            sounds.append(contentsOf: extra.sounds.filter { cue in !sounds.contains { $0.sound == cue.sound } })
            tools.append(contentsOf: extra.calmTools.filter { !tools.contains($0) })
        }
        lines.append(template.ending)

        let pages = lines.enumerated().map { index, line in
            StoryPage(
                id: "p\(index + 1)", sentence: line.text, sometimesNote: line.note, scene: line.scene, kind: line.kind
            )
        }
        return Story(
            id: makeID(),
            title: template.title,
            language: request.language.rawValue,
            review: .placeholder,
            pages: pages,
            practice: StoryPractice(steps: template.steps, sounds: sounds, calmTools: tools),
            draftSource: .template
        )
    }
}

/// Template content. Each template keeps the rules it is checked against: short literal sentences, "might" and
/// "usually" instead of promises, at least two describing pages per "I can", and a good ending.
enum Templates {
    struct Line: Sendable {
        let text: String
        let kind: PageKind
        let scene: StoryScene
        var note: String?
    }

    struct Extra: Sendable {
        let keywords: [String]
        let lines: [Line]
        var sounds: [SoundCue] = []
        var calmTools: [CalmTool] = []
    }

    struct Template: Sendable {
        let title: String
        let opening: [Line]
        let ending: Line
        let steps: [PracticeStep]
        let sounds: [SoundCue]
        let calmTools: [CalmTool]
        var extras: [Extra] = []
    }

    static func template(for event: EventKind, language: StoryLanguage) -> Template {
        switch language {
        case .english: english(event)
        case .indonesian: indonesian(event)
        }
    }

    private static func step(_ id: String, _ label: String, _ pictogram: Pictogram) -> PracticeStep {
        PracticeStep(id: id, label: label, pictogram: pictogram)
    }

    // MARK: English

    private static func english(_ event: EventKind) -> Template {
        let loud = Extra(
            keywords: ["loud", "noisy", "crowd", "busy"],
            lines: [
                Line(text: "Some places might be loud.", kind: .describes, scene: .waitingRoom),
                Line(text: "I can wear my headphones.", kind: .iCan, scene: .waitingRoom),
            ],
            calmTools: [.headphones]
        )
        let fireworks = Extra(
            keywords: ["firework"],
            lines: [
                Line(text: "At night there might be fireworks.", kind: .describes, scene: .streetTrip),
                Line(text: "Fireworks are loud and bright in the sky.", kind: .describes, scene: .streetTrip),
            ],
            sounds: [SoundCue(sound: .fireworks, label: "Fireworks (bang and crackle)")],
            calmTools: [.headphones]
        )
        switch event {
        case .dentist:
            return Template(
                title: "Going to the dentist",
                opening: [
                    Line(text: "Today I am going to the dentist.", kind: .describes, scene: .waitingRoom),
                    Line(
                        text: "I wait in the waiting room.", kind: .describes, scene: .waitingRoom,
                        note: "Sometimes we wait a long time. That is okay."
                    ),
                    Line(text: "The dentist has a big chair that goes back.", kind: .describes, scene: .bigChair),
                    Line(text: "I can hold my favourite toy.", kind: .iCan, scene: .bigChair),
                ],
                ending: Line(text: "The dentist counts my teeth. Then I go home.", kind: .endsWell, scene: .bigChair),
                steps: [
                    step("car", "Go in the car", .car), step("wait", "Wait in the waiting room", .waiting),
                    step("teeth", "The dentist counts my teeth", .dentist), step("home", "Go home", .home),
                ],
                sounds: [
                    SoundCue(sound: .dentistDrill, label: "The little brush (it buzzes)"),
                    SoundCue(sound: .suction, label: "The water straw (it slurps)"),
                ],
                calmTools: [.headphones, .sunglasses, .squishy, .breathe],
                extras: [loud]
            )
        case .haircut:
            return Template(
                title: "Getting a haircut",
                opening: [
                    Line(text: "Today I am getting a haircut.", kind: .describes, scene: .bigChair),
                    Line(text: "I sit in a big chair. A cape goes around me.", kind: .describes, scene: .bigChair),
                    Line(
                        text: "The clippers might buzz near my ears.", kind: .describes, scene: .bigChair,
                        note: "Sometimes the hairdresser uses scissors instead."
                    ),
                    Line(text: "I can hold my squishy toy.", kind: .iCan, scene: .bigChair),
                ],
                ending: Line(text: "Then I look in the mirror and go home.", kind: .endsWell, scene: .pipRoom),
                steps: [
                    step("car", "Go in the car", .car), step("wait", "Wait for my turn", .waiting),
                    step("chair", "Sit in the big chair", .waiting), step("home", "Go home", .home),
                ],
                sounds: [SoundCue(sound: .hairClipper, label: "The clippers (they buzz)")],
                calmTools: [.headphones, .squishy, .breathe, .holdHand],
                extras: [loud]
            )
        case .familyVisit:
            return Template(
                title: "Visiting family",
                opening: [
                    Line(text: "Today my family visits Grandma's house.", kind: .describes, scene: .familyVisit),
                    Line(
                        text: "Many people might be there. Some people talk loudly.", kind: .describes,
                        scene: .familyVisit
                    ),
                    Line(text: "People usually say hello and shake hands.", kind: .describes, scene: .familyVisit),
                    Line(text: "When it is loud, I can find a quiet corner.", kind: .iCan, scene: .familyVisit),
                ],
                ending: Line(text: "Then we go home, and I can rest.", kind: .endsWell, scene: .pipRoom),
                steps: [
                    step("car", "Go in the car", .car), step("hello", "Say hello", .home),
                    step("eat", "Eat together", .breakfast), step("home", "Go home", .home),
                ],
                sounds: [],
                calmTools: [.headphones, .quietCorner, .breakCard, .askForHelp],
                extras: [fireworks]
            )
        case .fireDrill:
            return Template(
                title: "A fire drill at school",
                opening: [
                    Line(text: "Sometimes my school has a fire drill.", kind: .describes, scene: .streetTrip),
                    Line(text: "The alarm might be loud.", kind: .describes, scene: .streetTrip),
                    Line(text: "We walk outside together with my teacher.", kind: .describes, scene: .streetTrip),
                    Line(text: "I can cover my ears or wear my headphones.", kind: .iCan, scene: .streetTrip),
                ],
                ending: Line(text: "Then we go back to class.", kind: .endsWell, scene: .waitingRoom),
                // No step cards yet: the pictogram set has no school, alarm or walking picture.
                steps: [],
                sounds: [
                    SoundCue(sound: .fireAlarm, label: "The fire alarm"),
                    SoundCue(sound: .schoolBell, label: "The school bell"),
                ],
                calmTools: [.headphones, .holdHand, .breathe, .askForHelp]
            )
        case .newPlace:
            return Template(
                title: "Going somewhere new",
                opening: [
                    Line(text: "Today I am going to a new place.", kind: .describes, scene: .streetTrip),
                    Line(text: "There might be new people there.", kind: .describes, scene: .waitingRoom),
                    Line(text: "A grown-up I know stays with me.", kind: .describes, scene: .waitingRoom),
                    Line(text: "I can hold my favourite toy.", kind: .iCan, scene: .waitingRoom),
                ],
                ending: Line(text: "Then I go home.", kind: .endsWell, scene: .pipRoom),
                // No step cards yet: the pictogram set has no school, alarm or walking picture.
                steps: [],
                sounds: [],
                calmTools: [.headphones, .squishy, .holdHand, .askForHelp],
                extras: [loud]
            )
        }
    }

    // MARK: Indonesian

    private static func indonesian(_ event: EventKind) -> Template {
        let loud = Extra(
            keywords: ["ramai", "berisik", "keras", "bising"],
            lines: [
                Line(text: "Mungkin ada tempat yang bising.", kind: .describes, scene: .waitingRoom),
                Line(text: "Aku boleh memakai headphone.", kind: .iCan, scene: .waitingRoom),
            ],
            calmTools: [.headphones]
        )
        let fireworks = Extra(
            keywords: ["kembang api", "petasan"],
            lines: [
                Line(text: "Malam hari mungkin ada kembang api.", kind: .describes, scene: .streetTrip),
                Line(text: "Kembang api bunyinya keras dan cahayanya terang.", kind: .describes, scene: .streetTrip),
            ],
            sounds: [SoundCue(sound: .fireworks, label: "Kembang api (dar dan kretek-kretek)")],
            calmTools: [.headphones]
        )
        switch event {
        case .dentist:
            return Template(
                title: "Pergi ke dokter gigi",
                opening: [
                    Line(text: "Hari ini aku pergi ke dokter gigi.", kind: .describes, scene: .waitingRoom),
                    Line(
                        text: "Aku menunggu di ruang tunggu.", kind: .describes, scene: .waitingRoom,
                        note: "Kadang-kadang kita menunggu lama. Itu tidak apa-apa."
                    ),
                    Line(text: "Dokter gigi punya kursi besar yang bisa miring.", kind: .describes, scene: .bigChair),
                    Line(text: "Aku boleh memegang mainan kesayanganku.", kind: .iCan, scene: .bigChair),
                ],
                ending: Line(
                    text: "Dokter gigi menghitung gigiku. Lalu aku pulang.", kind: .endsWell, scene: .bigChair),
                steps: [
                    step("car", "Naik mobil", .car), step("wait", "Menunggu di ruang tunggu", .waiting),
                    step("teeth", "Dokter gigi menghitung gigiku", .dentist), step("home", "Pulang", .home),
                ],
                sounds: [
                    SoundCue(sound: .dentistDrill, label: "Sikat kecil (bunyinya berdengung)"),
                    SoundCue(sound: .suction, label: "Sedotan air (bunyinya menyedot)"),
                ],
                calmTools: [.headphones, .sunglasses, .squishy, .breathe],
                extras: [loud]
            )
        case .haircut:
            return Template(
                title: "Potong rambut",
                opening: [
                    Line(text: "Hari ini aku potong rambut.", kind: .describes, scene: .bigChair),
                    Line(text: "Aku duduk di kursi besar. Kain menutupi badanku.", kind: .describes, scene: .bigChair),
                    Line(
                        text: "Alat cukur mungkin berdengung di dekat telingaku.", kind: .describes, scene: .bigChair,
                        note: "Kadang-kadang tukang cukur memakai gunting."
                    ),
                    Line(text: "Aku boleh memegang mainan empukku.", kind: .iCan, scene: .bigChair),
                ],
                ending: Line(text: "Lalu aku melihat cermin dan pulang.", kind: .endsWell, scene: .pipRoom),
                steps: [
                    step("car", "Naik mobil", .car), step("wait", "Menunggu giliranku", .waiting),
                    step("chair", "Duduk di kursi besar", .waiting), step("home", "Pulang", .home),
                ],
                sounds: [SoundCue(sound: .hairClipper, label: "Alat cukur (bunyinya berdengung)")],
                calmTools: [.headphones, .squishy, .breathe, .holdHand],
                extras: [loud]
            )
        case .familyVisit:
            return Template(
                title: "Lebaran di rumah Nenek",
                opening: [
                    Line(
                        text: "Saat Lebaran, keluargaku berkunjung ke rumah Nenek.", kind: .describes,
                        scene: .familyVisit),
                    Line(
                        text: "Mungkin ada banyak orang. Ada yang berbicara keras.", kind: .describes,
                        scene: .familyVisit
                    ),
                    Line(
                        text: "Biasanya orang bersalaman dan bilang \u{201C}Mohon maaf lahir dan batin\u{201D}.",
                        kind: .describes, scene: .familyVisit
                    ),
                    Line(text: "Kalau ramai, aku boleh mencari pojok yang tenang.", kind: .iCan, scene: .familyVisit),
                ],
                ending: Line(text: "Lalu kami pulang, dan aku bisa beristirahat.", kind: .endsWell, scene: .pipRoom),
                steps: [
                    step("car", "Naik mobil", .car), step("salam", "Bersalaman", .home),
                    step("eat", "Makan bersama", .breakfast), step("home", "Pulang", .home),
                ],
                sounds: [],
                calmTools: [.headphones, .quietCorner, .breakCard, .askForHelp],
                extras: [fireworks]
            )
        case .fireDrill:
            return Template(
                title: "Latihan kebakaran di sekolah",
                opening: [
                    Line(
                        text: "Kadang-kadang sekolahku mengadakan latihan kebakaran.", kind: .describes,
                        scene: .streetTrip),
                    Line(text: "Bunyi alarmnya mungkin keras.", kind: .describes, scene: .streetTrip),
                    Line(text: "Kami berjalan keluar bersama guruku.", kind: .describes, scene: .streetTrip),
                    Line(text: "Aku boleh menutup telinga atau memakai headphone.", kind: .iCan, scene: .streetTrip),
                ],
                ending: Line(text: "Lalu kami kembali ke kelas.", kind: .endsWell, scene: .waitingRoom),
                // No step cards yet: the pictogram set has no school, alarm or walking picture.
                steps: [],
                sounds: [
                    SoundCue(sound: .fireAlarm, label: "Alarm kebakaran"),
                    SoundCue(sound: .schoolBell, label: "Bel sekolah"),
                ],
                calmTools: [.headphones, .holdHand, .breathe, .askForHelp]
            )
        case .newPlace:
            return Template(
                title: "Pergi ke tempat baru",
                opening: [
                    Line(text: "Hari ini aku pergi ke tempat baru.", kind: .describes, scene: .streetTrip),
                    Line(text: "Mungkin ada orang-orang baru di sana.", kind: .describes, scene: .waitingRoom),
                    Line(text: "Orang dewasa yang aku kenal menemaniku.", kind: .describes, scene: .waitingRoom),
                    Line(text: "Aku boleh memegang mainan kesayanganku.", kind: .iCan, scene: .waitingRoom),
                ],
                ending: Line(text: "Lalu aku pulang.", kind: .endsWell, scene: .pipRoom),
                // No step cards yet: the pictogram set has no school, alarm or walking picture.
                steps: [],
                sounds: [],
                calmTools: [.headphones, .squishy, .holdHand, .askForHelp],
                extras: [loud]
            )
        }
    }
}
