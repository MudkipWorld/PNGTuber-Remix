class_name Visemes


## List of standard visemes
enum VISEME {
	## Silent viseme
	VISEME_SILENT = 0,

	## Viseme CH created by:
	## - Voiceless postalveolar affricate [tS] (CHeck, CHoose, beaCH, marCH)
	## - Voiced postalveolar affricate [dZ] (Job, aGe, maJor, Joy, Jump)
	## - Voiceless postalveolar fricative [S] (SHe, puSH, SHeep)
	VISEME_TH = 1,

	## Viseme SS created by:
	## - Voiceless alveolar fricative [s] (Sir, See, Seem)
	## - Voiced alveolar fricative [z] (aS, hiS, Zoo)
	VISEME_SS = 2,
	## Plosive Viseme DD created by:
	## - Voiceless alveolar plosive [t] (Take, haT, sTew)
	## - Voiced alveolar plosive [d] (Day, haD, Dig)
	## Note: Plosive (stop) phonemes are difficult to record.
	VISEME_DD = 3,

	## Viseme E created by:
	## - Close-mid front unrounded vowel [e] (Ever, bEd)
	VISEME_E = 4,

	## Viseme FF created by:
	## - Voiceless labiodental fricative [f] (Fan, Five)
	## - Voiced labiodental fricative [v] (Van, Vest)
	VISEME_FF = 5,

	## Viseme I created by:
	## - Near-close front unrounded vowel [I] (fIx, offIce, kIt)
	VISEME_I = 6,

	## Viseme O created by:
	## - Open-mid back rounded vowel [O] (Otter, stOp, nOt)
	VISEME_O = 7,

	## Viseme PP created by:
	## - Voiceless bilabial plosive [p] (Pat, Put, Pack)
	## - Voiced bilabial plosive [b] (Bat, tuBe, Bed)
	## - Bilabial nasal [m] (Mat, froM, Mouse)
	## Note: Plosive (stop) phonemes are difficult to record.
	VISEME_PP = 8,

	## Viseme RR created by:
	## - Alveolar trill [r] (Red, fRom, Ram)
	VISEME_RR = 9,


	## Viseme U created by:
	## - Close back rounded vowel [u] (tOO, feW, bOOm)
	VISEME_U = 10,

	## Viseme aa created by:
	## - Open back unrounded vowel [A] (cAr, Art, fAther)
	VISEME_AA = 11,

	## Plosive Viseme kk created by:
	## - Voiceless velar plosive [k] (Call, weeK, sCat)
	## - Voiced velar plosive [g] (Gas, aGo, Game)
	## Note: Plosive (stop) phonemes are difficult to record.
	VISEME_G = 12,

	## Viseme nn created by:
	## - Alveolar nasal [n] (Not, aNd, Nap)
	## - Alveolar lateral approximant [l] (Lot, chiLd, Lay)
	VISEME_L = 13,

	## Count of visemes
	COUNT = 14
}


## Map of viseme to phonemes
const VISEME_PHONEME_MAP := {
	VISEME.VISEME_SILENT: [],
	VISEME.VISEME_TH: [
		Phonemes.PHONEME.PHONEME_TS,
	],
	VISEME.VISEME_DD: [
		Phonemes.PHONEME.PHONEME_T,
	],
	VISEME.VISEME_E: [
		Phonemes.PHONEME.PHONEME_E,
	],
	VISEME.VISEME_FF: [
		Phonemes.PHONEME.PHONEME_V,
	],
	VISEME.VISEME_I: [
		Phonemes.PHONEME.PHONEME_I,
	],
	VISEME.VISEME_O: [
		Phonemes.PHONEME.PHONEME_O,
	],
	VISEME.VISEME_PP: [
		Phonemes.PHONEME.PHONEME_B,
	],
	VISEME.VISEME_RR: [
		Phonemes.PHONEME.PHONEME_R,
	],
	VISEME.VISEME_SS: [
		Phonemes.PHONEME.PHONEME_S,
	],

	VISEME.VISEME_U: [
		Phonemes.PHONEME.PHONEME_OU,
	],
	VISEME.VISEME_AA: [
		Phonemes.PHONEME.PHONEME_A,
	],
	VISEME.VISEME_G: [
		Phonemes.PHONEME.PHONEME_G,
	],
	VISEME.VISEME_L: [
		Phonemes.PHONEME.PHONEME_L,
	],
}
