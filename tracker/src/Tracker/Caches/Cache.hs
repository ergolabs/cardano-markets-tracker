module Tracker.Caches.Cache where

import GHC.Natural
import Prelude
import System.Logging.Hlog          (Logging(Logging, debugM), MakeLogging(..))
import Data.ByteString.UTF8         as BSU
import Data.ByteString              as BS
import Database.Redis               as Redis
import Control.Monad.Trans.Resource
import Control.Monad.IO.Unlift
import RIO

import Tracker.Models.AppConfig

data Cache f = Cache
  { getLastIndex :: f Int
  , putLastIndex :: Int -> f ()
  }

mkCache
  :: (MonadIO i, MonadResource i, MonadIO f) 
  => RedisSettings
  -> i (Cache f)
mkCache settings =
    fmap (\connection -> Cache  (getLastIndex' connection) (putLastIndex' connection)) connectionF
  where
    connectionF = mkConnection settings

constantDefaultIndex :: Int
constantDefaultIndex = 0

constantKey :: ByteString
constantKey = "tracker_executed_ops_min_index"

mkConnection
  :: (MonadIO i, MonadResource i) 
  => RedisSettings
  -> i Connection
mkConnection RedisSettings{..} =
  liftResourceT $ lift $ checkedConnect
    defaultConnectInfo 
      { connectHost = redisHost
      }

putLastIndex'
  :: (MonadIO f)
  => Connection
  -> Int
  -> f ()
putLastIndex' conn index =
  void $ liftIO $ runRedis conn $ do
    Redis.set constantKey (BSU.fromString $ show index)

getLastIndex'
  :: (MonadIO f)
  => Connection
  -> f Int
getLastIndex' conn = liftIO $ do
  res <- runRedis conn $ Redis.get constantKey
  let 
    actualIndex =
      case res of
        Right value ->
          case value of
            Just bs -> read $ BSU.toString bs :: Int
            _       -> constantDefaultIndex
        Left err -> constantDefaultIndex
  pure actualIndex