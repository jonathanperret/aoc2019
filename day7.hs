import Data.List
main = mapM_ putStrLn $ map (unwords . map show) $ permutations [5..9]
