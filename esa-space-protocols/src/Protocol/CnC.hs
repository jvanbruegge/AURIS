{-# LANGUAGE
    OverloadedStrings
    , BangPatterns
    , NoImplicitPrelude
#-}
module Protocol.CnC
  (
    receiveCnCC
    , scoeCommandC
    , SCOECommand(..)
    , generateAckData
  )
where

import           RIO
import qualified RIO.ByteString                as BS

import           ByteString.StrictBuilder

import           Conduit
import           Data.Conduit.Attoparsec
import qualified Data.ByteString.Char8         as BCS
import           Data.Attoparsec.ByteString.Char8
                                               as A
import           Data.Semigroup                 ( (<>) )

import qualified Data.Vector                   as V
import           Data.Char

import           Data.PUS.PUSPacket
import           Data.PUS.MissionSpecific.Definitions

import           Protocol.ProtocolInterfaces




-- if we have SCOE packet, and it has a secondary header, it is a binary
-- TC, else an ASCII one.
isASCIICc :: ProtocolPacket PUSPacket -> Bool
isASCIICc (ProtocolPacket IF_CNC pusPkt) =
  let hdr = pusPkt ^. pusHdr
  in  hdr ^. pusHdrTcVersion == 3 && hdr ^. pusHdrDfhFlag == False
isASCIICc _ = False


receiveCnCC
  :: (MonadIO m, MonadReader env m, HasLogFunc env)
  => PUSMissionSpecific
  -> ConduitT ByteString (ProtocolPacket PUSPacket) m ()
receiveCnCC missionSpecific = do
  conduitParserEither (pusPktParser missionSpecific IF_CNC) .| sink
 where
  sink = awaitForever $ \tc -> do
    case tc of
      Left err -> logError $ "Error decoding CnC packet: " <> displayShow err
      Right (_, pkt) -> yield pkt

      
scoeCommandC :: (Monad m) => ConduitT (ProtocolPacket PUSPacket) SCOECommand m ()
scoeCommandC = awaitForever $ \pusPkt -> do 
    case extractCommand pusPkt of 
        Just scoeCmd -> yield scoeCmd 
        Nothing -> scoeCommandC 




-- sendTC :: Socket -> B.ByteString -> IO ()
-- sendTC handle msg = do
--   logStr nctrsArea $ "Sending SCOE TC ACK: " ++ hexDumpString msg
--   sendAll handle msg


-- sendTM :: Socket -> B.ByteString -> Int -> IO ()
-- sendTM sock pl _leaps = do
--   sendAll sock pl


extractCommand :: ProtocolPacket PUSPacket -> Maybe SCOECommand
extractCommand cpkt@(ProtocolPacket IF_CNC pusPkt) = if isASCIICc cpkt
  then case parse scoeCommandParser (pusPkt ^. pusData) of
    Fail {} -> Nothing
    Partial _  -> Nothing
    Done _ res -> Just res
  else Nothing
extractCommand _ = Nothing


data SCOECommand = SCOECommand {
        sccCommand :: ByteString,
        sccArgs :: V.Vector ByteString
    } deriving (Show, Read)


scoeCommandParser :: Parser SCOECommand
scoeCommandParser = do
  cmd <- commandParser
  void space
  args <- argumentListParser
  return $! SCOECommand cmd (V.fromList args)


commandParser :: Parser ByteString
commandParser = BCS.map toUpper <$> A.takeWhile (not . A.isSpace)

argumentParser :: Parser ByteString
argumentParser = BCS.map toUpper <$> A.takeWhile (not . A.isSpace)

argumentListParser :: Parser [ByteString]
argumentListParser = argumentParser `A.sepBy` space



generateAckData :: SCOECommand -> Maybe ByteString -> ByteString
generateAckData (SCOECommand "TRANSFER" args) Nothing =
  builderBytes $ bytes "ACK " <> bytes "TRANSFER " <> bytes (args V.! 0)
generateAckData (SCOECommand "TRANSFER" args) (Just reason) =
  builderBytes
    $  bytes "NAK "
    <> bytes "TRANSFER "
    <> bytes (args V.! 0)
    <> bytes " "
    <> bytes reason

generateAckData (SCOECommand "ONLINE" _args) Nothing =
  builderBytes $ bytes "ACK " <> bytes "ONLINE "
generateAckData (SCOECommand "ONLINE" _args) (Just reason) =
  builderBytes $ bytes "NAK " <> bytes "ONLINE " <> bytes reason

generateAckData (SCOECommand "OFFLINE" _args) Nothing =
  builderBytes $ bytes "ACK " <> bytes "OFFLINE "
generateAckData (SCOECommand "OFFLINE" _args) (Just reason) =
  builderBytes $ bytes "NAK " <> bytes "OFFLINE " <> bytes reason

generateAckData (SCOECommand "RESET" _args) Nothing = "ACK " <> "RESET "
generateAckData (SCOECommand "RESET" _args) (Just reason) =
  "NAK " <> "RESET " <> " " <> reason

generateAckData (SCOECommand "RESTART" args) Nothing =
  "ACK " <> "RESTART " <> args V.! 0
generateAckData (SCOECommand "RESTART" args) (Just reason) =
  "NAK " <> "RESTART " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "START" args) Nothing =
  "ACK " <> "START " <> args V.! 0
generateAckData (SCOECommand "START" args) (Just reason) =
  "NAK " <> "START " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "STOP" args) Nothing =
  "ACK " <> "STOP " <> args V.! 0
generateAckData (SCOECommand "STOP" args) (Just reason) =
  "NAK " <> "STOP " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "APPLY" args) Nothing =
  "ACK " <> "APPLY " <> args V.! 0
generateAckData (SCOECommand "APPLY" args) (Just reason) =
  "NAK " <> "APPLY " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "SET" args) Nothing =
  "ACK " <> "SET " <> args V.! 0
generateAckData (SCOECommand "SET" args) (Just reason) =
  "NAK " <> "SET " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "REPORTPARA" args) Nothing =
  "ACK " <> "REPORTPARA " <> args V.! 0
generateAckData (SCOECommand "REPORTPARA" args) (Just reason) =
  "NAK " <> "REPORTPARA " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "TEST" args) Nothing =
  "ACK " <> "TEST " <> args V.! 0
generateAckData (SCOECommand "TEST" args) (Just reason) =
  "NAK " <> "TEST " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "REPORT" args) Nothing =
  "ACK " <> "REPORT " <> args V.! 0
generateAckData (SCOECommand "REPORT" args) (Just reason) =
  "NAK " <> "REPORT " <> args V.! 0 <> " " <> reason

generateAckData (SCOECommand "GETTM" args) Nothing =
  "ACK " <> "GETTM " <> args V.! 0
generateAckData (SCOECommand "GETTM" args) (Just reason) =
  "NAK " <> "GETTM " <> args V.! 0 <> " " <> reason


generateAckData (SCOECommand x args) Nothing =
  "ACK " <> x <> " " <> if V.length args >= 1 then args V.! 0 else BS.empty
generateAckData (SCOECommand x args) (Just reason) =
  "ACK " <> x <> " " <> arg1 <> " " <> reason
  where arg1 = if V.length args >= 1 then args V.! 0 else BS.empty
