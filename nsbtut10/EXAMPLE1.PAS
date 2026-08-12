Program Adlib;

{----------------------------------
 AdLib compatible fm-sound routines

    Copyright Tapio Äijälä 1994.

   Use and distribute freely, but
  please notice me in somewhere on
   your product if you use these
             routines!

              Thanks.
 ----------------------------------}

Uses crt;

Type  OperatorType = Record
       AmVibEgKsrMultiplier : Byte;
       KslOutputlevel       : Byte;
       AttackDecay          : Byte;
       SustainRelease       : Byte;
       Waveform             : Byte;
      End;

      InstrumentType = Record
       Operator1            : OperatorType;
       Operator2            : OperatorType;
       FeedbackConnectionTy : Byte;
      End;

Const Notes                 : Array [1..8,1..12] of Real =
                             ((16.352,17.324,18.354,19.445,20.601,21.286,23.124,24.499,25.956,27.500,29.135,30.867),
                              (32.703,34.648,36.708,38.890,41.203,43.653,46.249,48.999,51.913,55.000,58.270,61.735),
                              (65.406,69.295,73.416,77.781,82.406,87.307,92.499,97.998,103.82,110.00,116.54,123.47),
                              (130.81,138.59,146.83,155.56,164.81,174.61,184.99,195.99,207.65,220.00,233.08,246.94),
                              (261.63,277.18,293.66,311.13,329.63,349.23,369.99,391.99,415.31,440.00,466.16,493.88),
                              (523.25,554.37,587.33,622.25,659.26,698.46,739.99,783.99,830.61,880.00,932.32,987.77),
                              (1046.5,1108.7,1174.7,1244.5,1318.5,1396.9,1480.0,1568.0,1661.2,1760.0,1864.7,1975.5),
                              (2093.0,2217.5,2349.3,2489.0,2637.0,2793.8,2960.0,3136.0,3322.4,3520.0,3729.3,3951.1));

Var   Instrument            : InstrumentType;
      apu                   : Byte;

Procedure WriteR(index, data : Byte); Assembler;

{Writes given data to given register (index) of AdLib compatible soundcard}

ASM
    MOV    AL,INDEX
    MOV    DX,$0388
    OUT    DX,AL
    MOV    CX,6
   @WAIT1:
    IN     AL,DX
    LOOP   @WAIT1
    MOV    DX,$0389
    MOV    AL,DATA
    OUT    DX,AL
    MOV    CX,35
   @WAIT2:
    IN     AL,DX
    LOOP   @WAIT2
End;

Function IsSoundcardInstalled : Boolean;

{Is AdLib compatible soundcard installed? Returns TRUE if AdLib compatible
 soundcard is founded else FALSE.}

Var status1 : Byte;
    status2 : Byte;

Begin
 WriteR($4,$60);
 WriteR($4,$80);
 status1 := Port[$0388];
 WriteR($2,$FF);
 WriteR($4,$21);
 Delay(10);
 status2 := Port[$0388];
 WriteR($4,$60);
 WriteR($4,$80);
 If (status1 And $E0 = 00) And (status2 And $E0 = $C0) then
  IsSoundcardInstalled := True Else IsSoundcardInstalled := False;
End;

Procedure ResetSoundcard;

{Resets soundcard by writing zero to every register in a soundcard.}

Begin
 For apu := 1 to 244 Do WriteR(apu,0);
End;

Procedure PlaySound(channel, note, octave : Byte; inst : InstrumentType);

{Starts playing a sound in given channel with given instrument, note and
 octave information.}

Var ope        : Byte;
    a1         : Byte;
    a2         : LongInt;
    a3         : Word;
    OctaveNote : Byte;
    FNum       : Byte;
    FNumHi     : Byte;

Begin
 a1 := 32;
 OctaveNote := a1 Or (Octave Shl 2);
 a2 := 1;
 For a1 := 1 to 20 - Octave + 1 Do a2 := a2 * 2;
 a3 := Round(Notes[octave,note] * a2 / 49716);
 FNumHi := a3 Shr 10;
 OctaveNote := OctaveNote Or FNumHi;
 FNum := a3 Shr 2;
 Case Channel Of
  0 : ope := $00;
  1 : ope := $01;
  2 : ope := $02;
  3 : ope := $08;
  4 : ope := $09;
  5 : ope := $0A;
  6 : ope := $10;
  7 : ope := $11;
  8 : ope := $12;
 End;
 WriteR($20 + ope,inst.operator1.AmVibEgKsrMultiplier);
 WriteR($40 + ope,inst.operator1.KslOutputlevel);
 WriteR($60 + ope,inst.operator1.AttackDecay);
 WriteR($80 + ope,inst.operator1.SustainRelease);
 WriteR($E0 + ope,inst.operator1.Waveform);
 WriteR($23 + ope,inst.operator2.AmVibEgKsrMultiplier);
 WriteR($43 + ope,inst.operator2.KslOutputlevel);
 WriteR($63 + ope,inst.operator2.AttackDecay);
 WriteR($83 + ope,inst.operator2.SustainRelease);
 WriteR($E3 + ope,inst.operator2.Waveform);
 WriteR($C0 + channel,inst.FeedbackConnectionTy);
 WriteR($A0 + channel,FNum);
 WriteR($B0 + channel,OctaveNote);
End;

Procedure StopSound(channel : Byte);

{Stops playing in given channel.}

Var ope : Byte;

Begin
 Case Channel Of
  0 : ope := 00;
  1 : ope := 01;
  2 : ope := 02;
  3 : ope := 03;
  4 : ope := 04;
  5 : ope := 05;
  6 : ope := 06;
  7 : ope := 07;
  8 : ope := 08;
 End;
 WriteR($B0 + ope,0);
End;

Begin {Begin of main program}
 If IsSoundCardInstalled <> True then Halt(1);
 ResetSoundCard; {Resets soundcard}
 Instrument.Operator1.AmVibEgKsrMultiplier := $01; {Create some kind of instrument...}
 Instrument.Operator1.KslOutputlevel := $10;
 Instrument.Operator1.AttackDecay := $4c;
 Instrument.Operator1.SustainRelease := $0;
 Instrument.Operator1.Waveform := $0;
 Instrument.Operator2.AmVibEgKsrMultiplier := $01;
 Instrument.Operator2.KslOutputlevel := $0f;
 Instrument.Operator2.AttackDecay := $63;
 Instrument.Operator2.SustainRelease := $ff;
 Instrument.Operator2.Waveform := $0;
 PlaySound(0,1,5,Instrument); {Play created instrument in 7 channels}
 PlaySound(1,2,5,Instrument);
 PlaySound(2,3,5,Instrument);
 PlaySound(3,4,5,Instrument);
 PlaySound(4,5,5,Instrument);
 PlaySound(5,6,5,Instrument);
 PlaySound(6,7,5,Instrument);
 Delay(2500); {Wait a little bit}
 StopSound(0);
 StopSound(1);
 StopSound(2);
 StopSound(3);
 StopSound(4);
 StopSound(5);
 StopSound(6);
 ResetSoundCard; {Resets soundcard - Just to be sure...}
End.