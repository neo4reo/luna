{-# LANGUAGE OverloadedStrings #-}

module Main where

import Prologue as P hiding (Symbol)
import Criterion.Main
import Luna.Syntax.Text.Lexer
import System.Random
import System.IO (hFlush, hSetBuffering, stdout, BufferMode(NoBuffering))
import Data.Text (Text)
import qualified Data.Text as Text
import System.TimeIt

import qualified Data.Char as Char

import Conduit
import Data.Char (toUpper)
import Data.Attoparsec.Text as Parser
import Luna.Syntax.Text.Lexer.Stream
import Luna.Syntax.Text.Lexer (Symbol)
import System.IO (FilePath)

import Control.Monad.State.Layered

import Luna.Syntax.Text.Lexer.Analysis

eval :: NFData a => a -> IO a
eval = evaluate . force

liftExp :: (Int -> a) -> (Int -> a)
liftExp f = f . (10^)

expCodeGen :: (NFData a, Show a) => (Int -> a) -> (Int -> IO a)
expCodeGen f i = do
    -- putStrLn $ "generating input code (10e" <> show i <> " chars)"
    out <- eval $ liftExp f i
    -- putStrLn "code generated sucessfully"
    return out

maxExpCodeLen :: Int
maxExpCodeLen = 6

-- expCodeGenBench  :: (Int -> Text) -> Int -> Benchmark
-- expCodeGenBenchs :: (Int -> Text) -> [Benchmark]
expCodeGenBench  p f i = env (expCodeGen f i) $ bench ("10e" <> show i) . nf p
expCodeGenBenchs p f   = expCodeGenBench p f <$> [6..maxExpCodeLen]
--
--
-- mkCodeRandom :: Int -> VectorText
-- mkCodeRandom i = convert . P.take i $ Char.chr <$> randomRs (32,100) (mkStdGen 0)
--
mkCodeNumbers :: Int -> Text
mkCodeNumbers i = Text.replicate i $ convert ['0'..'9']

mkCodeTerminators, mkBigVariable :: Int -> Text
mkCodeTerminators i = Text.replicate i ";" ; {-# INLINE mkCodeTerminators #-}
mkBigVariable     i = Text.replicate i "a" ; {-# INLINE mkBigVariable     #-}

mkVariablesL1, mkVariablesL5, mkVariablesL10 :: Int -> Text
mkVariablesL1  i = Text.replicate i "a "          ; {-# INLINE mkVariablesL1  #-}
mkVariablesL5  i = Text.replicate i "abcde "      ; {-# INLINE mkVariablesL5  #-}
mkVariablesL10 i = Text.replicate i "abcdefghij " ; {-# INLINE mkVariablesL10 #-}



main = do
    -- pprint $ tagWithColumn 0 $ evalDefLexer "ala ' fo` x + y `\n o' ola"
    pprint $ tagDisabled $ evalDefLexer "off #def foo:\n      bar\n    def baz: pass"
    defaultMain
        [ bgroup "big variable"             $ expCodeGenBenchs evalDefLexer           mkBigVariable
        , bgroup "variables L1"             $ expCodeGenBenchs evalDefLexer           mkVariablesL1
        , bgroup "variables L5"             $ expCodeGenBenchs evalDefLexer           mkVariablesL5
        , bgroup "variables L10"            $ expCodeGenBenchs evalDefLexer           mkVariablesL10
        , bgroup "terminators"              $ expCodeGenBenchs evalDefLexer           mkCodeTerminators
        , bgroup "manual terminator parser" $ expCodeGenBenchs manualTerminatorParser mkCodeTerminators
        ]

manualTerminatorParser :: Text -> Either String [Char]
manualTerminatorParser = parseOnly $ many (char ';') ; {-# INLINE manualTerminatorParser #-}