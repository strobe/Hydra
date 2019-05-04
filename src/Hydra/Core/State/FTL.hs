module Hydra.Core.State.FTLI where

import           Hydra.Prelude

--
-- -- | State language. It reflects STM and its behavior.
-- data StateF next where
--   -- | Create variable.
--   NewVar :: a -> (D.StateVar a -> next) -> StateF next
--   -- | Read variable.
--   ReadVar :: D.StateVar a -> (a -> next) -> StateF next
--   -- | Write variable.
--   WriteVar :: D.StateVar a -> a -> (() -> next) -> StateF next
--   -- | Retry until some variable is changed in this atomic block.
--   Retry :: (a -> next) -> StateF next
--   -- | Eval "delayed" logger: it will be written after successfull state operation.
--   EvalStmLogger :: L.LoggerL () -> (() -> next) -> StateF next
--
-- makeFunctorInstance ''StateF
--
-- type StateL = Free StateF

class (StmLogger m, Monad m) => StateL m where
  newVar :: a -> m (D.StateVar a)
  readVar :: D.StateVar a -> m a
  writeVar :: D.StateVar a -> a -> m ()
  retry :: m a



class StateIO m where
  atomically :: StateL a -> m a
  newVarIO :: a -> m (D.StateVar a)
  readVarIO :: D.StateVar a -> m a
  writeVarIO :: D.StateVar a -> a -> m ()

-- | Create variable.
newVar :: a -> StateL (D.StateVar a)
newVar val = liftF $ NewVar val id

-- | Read variable.
readVar :: D.StateVar a -> StateL a
readVar var = liftF $ ReadVar var id

-- | Write variable.
writeVar :: D.StateVar a -> a -> StateL ()
writeVar var val = liftF $ WriteVar var val id

-- | Modify variable with function.
modifyVar :: D.StateVar a -> (a -> a) -> StateL ()
modifyVar var f = readVar var >>= writeVar var . f

-- | Retry until some variable is changed in this atomic block.
retry :: StateL a
retry = liftF $ Retry id

-- | Eval "delayed" logger: it will be written after successfull state operation.
evalStmLogger :: L.LoggerL () -> StateL ()
evalStmLogger action = liftF $ EvalStmLogger action id

instance L.Logger StateL where
    logMessage level = evalStmLogger . L.logMessage level