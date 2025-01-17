{-|
Module      : Data.PUS.Types
Description : Collections of various PUS types
Copyright   : (c) Michael Oswald, 2019
License     : BSD-3
Maintainer  : michael.oswald@onikudaki.net
Stability   : experimental
Portability : POSIX

This module is a collection of various simple PUS types
-}
{-# LANGUAGE
    DeriveGeneric
    , GeneralizedNewtypeDeriving
    , NoImplicitPrelude
#-}
module Data.PUS.Types
    ( VCID(..)
    , mkVCID
    , vcidBuilder
    , vcidParser
    , SCID(..)
    , mkSCID
    , scidBuilder
    , scidParser
    , MAPID
    , mkMAPID
    , getMAPID
    , mapIDBuilder
    , mapIDParser
    , mapIDControl
    , Flag
    , toFlag
    , fromFlag
    , toBool
    , Ready(..)
    , Enable(..)
    , OnOff(..)
    , Initialized(..)
    , Good(..)
    , RequestID
    , getRqstID
    , mkRqstID
    , TransmissionMode(..)
    , transmissionModeBuilder
    , transmissionModeParser
    , PUSType
    , mkPUSType
    , PUSSubType
    , mkPUSSubType
    , pusTypeBuilder
    , pusSubTypeBuilder
    , pusTypeParser
    , pusSubTypeParser
    , SSC
    , getSSC
    , mkSSC
    , nextSSC
    , SourceID
    , mkSourceID
    , sourceIDBuilder
    , sourceIDParser
    , TMSegmentLen(..)
    , tmSegmentLength
    )
where


import           RIO                     hiding ( Builder )

import           Codec.Serialise
import           Data.Binary
import           Data.Aeson
import           ByteString.StrictBuilder
import           Data.Attoparsec.ByteString     ( Parser )
import qualified Data.Attoparsec.ByteString    as A
import qualified Data.Attoparsec.Binary        as A
import           Data.Bits

-- | Virtual Channel ID
newtype VCID = VCID { getVCID :: Word8 }
    deriving (Eq, Ord, Num, Show, Read, Generic)

-- | Smart constructor for the Virtual Channel ID
mkVCID :: Word8 -> VCID
mkVCID = VCID

instance Binary VCID
instance Serialise VCID
instance FromJSON VCID
instance ToJSON VCID where
    toEncoding = genericToEncoding defaultOptions
instance Hashable VCID

-- | A buidler for the VCID
vcidBuilder :: VCID -> Builder
vcidBuilder (VCID x) = word8 x

-- | A parser for the VCID
vcidParser :: Parser VCID
vcidParser = VCID <$> A.anyWord8


-- | The Spacecraft ID
newtype SCID = SCID { getSCID :: Word16 }
    deriving (Eq, Ord, Show, Read, Generic)

-- | Smart constructor for the S/C ID
mkSCID :: Word16 -> SCID
mkSCID = SCID

instance Binary SCID
instance Serialise SCID
instance FromJSON SCID
instance ToJSON SCID where
    toEncoding = genericToEncoding defaultOptions

-- | Builder for the S/C ID
scidBuilder :: SCID -> Builder
scidBuilder (SCID x) = word16BE x

-- | Parser for the S/C ID
scidParser :: Parser SCID
scidParser = SCID <$> A.anyWord16be



-- | The MAPID (Mulitplexer Access Point ID) used in the TC segmentation
-- layer
newtype MAPID = MAPID { getMAPID :: Word8 }
    deriving (Eq, Ord, Num, Show, Read, Generic)

-- | Smart constructor for the MAPID
mkMAPID :: Word8 -> MAPID
mkMAPID x = MAPID (x .&. 0x3F)

instance Binary MAPID
instance Serialise MAPID
instance FromJSON MAPID
instance ToJSON MAPID where
    toEncoding = genericToEncoding defaultOptions

-- | Builder for the MAPDI
mapIDBuilder :: MAPID -> Builder
mapIDBuilder (MAPID x) = word8 x

-- | Parser for the MAPID
mapIDParser :: Parser MAPID
mapIDParser = MAPID <$> A.anyWord8

-- | A special MAPID value which specifies, that this segment is not a
-- TC segment, but a control segment which commands the segmentation layer
-- on-board. Used in the TC authentication
mapIDControl :: MAPID
mapIDControl = MAPID 63


-- | 'Flag' for Ready/Not Ready
data Ready = Ready
-- | 'Flag' for Enable/Disable
data Enable = Enable
-- | 'Flag' for On/Off
data OnOff = OnOff
-- | 'Flag' for Initial/Not Initial. Used in one-time initialisations
data Initialized = Initialized
-- | 'Flag' for quality
data Good = Good


-- | Generic flag type. To be used with the types above (or new ones)
newtype Flag a = MkFlag Bool
    deriving (Eq, Ord, Show, Read, Generic)

instance Serialise (Flag a)
instance FromJSON (Flag a)
instance ToJSON (Flag a) where
    toEncoding = genericToEncoding defaultOptions


-- | Converts a type with the given Bool to a 'Flag'
toFlag :: t -> Bool -> Flag t
toFlag _ = MkFlag

-- | Converts from the 'Flag' to a 'Bool'. Takes also the type itself
fromFlag :: t -> Flag t -> Bool
fromFlag _ (MkFlag b) = b

-- | Direct conversion from the 'Flag' to a bool, suitable in if expressions
toBool :: Flag t -> Bool
toBool (MkFlag b) = b

-- | The Request ID type
newtype RequestID = RequestID { getRqstID :: Int64 }
    deriving (Eq, Ord, Num, Show, Read, Generic)

-- | Smart constructor for the 'RequestID'
mkRqstID :: Int64 -> RequestID
mkRqstID = RequestID

instance Binary RequestID
instance Serialise RequestID
instance FromJSON RequestID
instance ToJSON RequestID where
    toEncoding = genericToEncoding defaultOptions


-- | The Transmission Mode. Can be AD or BD
data TransmissionMode = AD | BD
    deriving (Eq, Ord, Enum, Show, Read, Generic)

instance Binary TransmissionMode
instance Serialise TransmissionMode
instance FromJSON TransmissionMode
instance ToJSON TransmissionMode where
    toEncoding = genericToEncoding defaultOptions

-- | Builder for the 'TransmissionMode'
transmissionModeBuilder :: TransmissionMode -> Builder
transmissionModeBuilder AD = word8 0
transmissionModeBuilder BD = word8 1

-- | Parser for the 'TransmissionMode'
transmissionModeParser :: Parser TransmissionMode
transmissionModeParser = do
    val <- A.anyWord8
    case val of
        0 -> pure AD
        _ -> pure BD

-- | PUS Packet Type
newtype PUSType = PUSType Word8
    deriving (Eq, Ord, Num, Show, Read, Generic)

-- | Smart constructor for the 'PUSType'
mkPUSType :: Word8 -> PUSType
mkPUSType = PUSType

-- | PUS Sub Type
newtype PUSSubType = PUSSubType Word8
    deriving (Eq, Ord, Num, Show, Read, Generic)

-- | Smart constructor for the 'PUSSubType'
mkPUSSubType :: Word8 -> PUSSubType
mkPUSSubType = PUSSubType

-- | Builder for the 'PUSType'
pusTypeBuilder :: PUSType -> Builder
pusTypeBuilder (PUSType x) = word8 x

-- | Builder for the 'PUSSubType'
pusSubTypeBuilder :: PUSSubType -> Builder
pusSubTypeBuilder (PUSSubType x) = word8 x

-- | Parser for the 'PUSType'
pusTypeParser :: Parser PUSType
pusTypeParser = PUSType <$> A.anyWord8

-- | Parser for the 'PUSSubType'
pusSubTypeParser :: Parser PUSSubType
pusSubTypeParser = PUSSubType <$> A.anyWord8



instance Binary PUSType
instance Serialise PUSType
instance FromJSON PUSType
instance ToJSON PUSType where
    toEncoding = genericToEncoding defaultOptions

instance Binary PUSSubType
instance Serialise PUSSubType
instance FromJSON PUSSubType
instance ToJSON PUSSubType where
    toEncoding = genericToEncoding defaultOptions


-- | Type for the source sequence count
newtype SSC = SSC { getSSC :: Word16 }
    deriving (Eq, Ord, Num, Show, Read, Generic)

-- | Smart constructor for a 'SSC'
mkSSC :: Word16 -> SSC
mkSSC = SSC

-- | Gives the next 'SSC' in order
nextSSC :: SSC -> SSC
nextSSC (SSC x) = SSC (x + 1)

instance Binary SSC
instance Serialise SSC
instance FromJSON SSC
instance ToJSON SSC where
    toEncoding = genericToEncoding defaultOptions
instance Hashable SSC

instance Display SSC where
    display (SSC x) = display x

newtype SourceID = SourceID { getSourceID :: Word8 }
    deriving (Eq, Ord, Show, Read, Generic)

mkSourceID :: Word8 -> SourceID
mkSourceID = SourceID

instance Binary SourceID
instance Serialise SourceID
instance FromJSON SourceID
instance ToJSON SourceID where
    toEncoding = genericToEncoding defaultOptions
instance NFData SourceID


-- | A buidler for the VCID
sourceIDBuilder :: SourceID -> Builder
sourceIDBuilder (SourceID x) = word8 x

-- | A parser for the VCID
sourceIDParser :: Parser SourceID
sourceIDParser = SourceID <$> A.anyWord8



-- | Used for specifying the segment length for TM frames
data TMSegmentLen = TMSegment256
    | TMSegment512
    | TMSegment1024
    | TMSegment65536
      deriving (Show, Read, Eq, Ord, Enum, Generic)

instance Binary TMSegmentLen
instance Serialise TMSegmentLen
instance FromJSON TMSegmentLen
instance ToJSON TMSegmentLen where
    toEncoding = genericToEncoding defaultOptions


-- | returns the length of the segment in bytes
tmSegmentLength :: TMSegmentLen -> Int
tmSegmentLength TMSegment256   = 256
tmSegmentLength TMSegment512   = 512
tmSegmentLength TMSegment1024  = 1024
tmSegmentLength TMSegment65536 = 65536
