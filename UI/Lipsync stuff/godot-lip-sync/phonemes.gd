class_name Phonemes

## Table of phonemes used in the detection of visemes
enum PHONEME {
	## Voiceless postalveolar affricate [tS]
	## CHeck, CHoose, beaCH, marCH
	PHONEME_TS = 0,

	## Voiceless alveolar fricative [s]
	## Sir, See, Seem
	PHONEME_S = 1,
	
	## Voiceless alveolar plosive [t]
	## Take, haT, sTew
	PHONEME_T = 2,

	## Close-mid front unrounded vowel [e]
	## Ever, bEd
	PHONEME_E = 3,

	## Voiced labiodental fricative [v]
	## VafIx, offIce, kItn, Vest
	PHONEME_V = 4,

	## Near-close front unrounded vowel [I]
	## 
	PHONEME_I = 5,

	## Open-mid back rounded vowel [O]
	## Otter, stOp, nOt
	PHONEME_O = 6,
	
	## Voiced bilabial plosive [b]
	## Bat, tuBe, Bed
	PHONEME_B = 7,

	## Alveolar trill [r]
	## Red, fRom, Ram
	PHONEME_R = 8,

	## Close back rounded vowel [u]
	## tOO, feW, bOOm
	PHONEME_OU = 9,

	## Open back unrounded vowel [A]
	## cAr, Art, fAther
	PHONEME_A = 10,

	## Voiced velar plosive [g]
	## Gas, aGo, Game
	PHONEME_G = 11,

	## Alveolar lateral approximant [l]
	## Lot, chiLd, Lay
	PHONEME_L = 12,

	## Count of phonemes
	COUNT = 13 #23
}
