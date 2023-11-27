library(stringr)
library(tidyverse)
library(readr)
library(flexplot)

###
# DEFINE FUNCTIONS
###

# Define a function to convert a Cardiff clause structure into a binary vector
convert_clause2vector <- function(clause) {
  linker <- as.numeric(str_detect(string = clause, pattern = "&"))
  #B <- as.numeric(str_detect(string = clause, pattern = "B"))
  A_before_S <- as.numeric(str_detect(string = clause, pattern = "A.*S.*M"))
  S <- as.numeric(str_detect(string = clause, pattern = "S"))
  #O <- as.numeric(str_detect(string = clause, pattern = ", O"))
  #N <- as.numeric(str_detect(string = clause, pattern = ", N"))
  A_after_S <- as.numeric(str_detect(string = clause, pattern = "S.*A.*M"))
  I <- as.numeric(str_detect(string = clause, pattern = "I"))
  #X <- as.numeric(str_detect(string = clause, pattern = "X"))
  M <- as.numeric(str_detect(string = clause, pattern = "M"))
  A_after_M <- as.numeric(str_detect(string = clause, pattern = "S.*M.*A"))
  C <- as.numeric(str_detect(string = clause, pattern = "C"))
  
  vec_rep <- c(linker, A_before_S, S, A_after_S, I, M, C, A_after_M)
  return(vec_rep)
}

# Define a function to convert a Cardiff nominal group structure into a binary vector
convert_ngp2vector <- function(clause) {
  linker <- as.numeric(str_detect(string = clause, pattern = "&"))
  qd <- as.numeric(str_detect(string = clause, pattern = "qd"))
  dd <- as.numeric(str_detect(string = clause, pattern = "dd"))
  m <- as.numeric(str_detect(string = clause, pattern = "m"))
  h <- as.numeric(str_detect(string = clause, pattern = "h"))
  vec_rep <- c(linker, qd, dd, m, h)
  return(vec_rep)
}

# Define a function to derive the Hamming distance between two binary vectors
hamming_dist <- function(vector1, vector2) {
  return(sum(vector1 != vector2))
}

# Define a function to apply hamming_dist() to every pair of binary vectors in a list
get_distances <- function(text) {
  # Initialise an empty vector to store distances
  distances <- numeric()
  
  # Loop through all pairs of vectors
  for (i in 1:(length(text) - 1)) {
    for (j in (i + 1):length(text)) {
      # Calculate Hamming Distance and append to the distances vector
      distances <- c(distances, hamming_dist(text[[i]], text[[j]]))
    }
  }
  return(distances)
}

# Define a function to convert all clause structures in passages into vectors
convert_all2vector <- function(data) {
  the_passage <- data %>%
    mutate(structure_vector = ifelse(unit == "clause", yes = lapply(data$structure, convert_clause2vector), no = lapply(data$structure, convert_ngp2vector)) ) %>%
    relocate(structure_vector, .after = structure)
  return(the_passage)
}

# Define a function to derive unit size (in terms of number of component elements) from binary vectors
# Use only after convert_all2vector()
get_unit_sizes <- function(data) {
  the_passage <- data %>%
    mutate(unit_size = structure_vector) %>%
    relocate(unit_size, .after = structure_vector)
  
  for (i in 1:length(the_passage$unit_size)) {
    the_passage$unit_size[i] <- sum(unlist(the_passage$unit_size[i]))
  }
  
  the_passage <- the_passage %>%
    mutate(unit_size = unlist(unit_size))
  
  return(the_passage)
}

###
#END DEFINE FUNCTIONS
###

# Import data from .csv file
passages <- as_tibble(read_csv("./passages_syntax.csv")) %>%
  filter(passage == "2c"| passage == "1c") %>%
  convert_all2vector %>%
  get_unit_sizes

# Summarise all clause and nominal group structures and their counts per passage
passages %>%
  select(c(passage, structure, unit)) %>%
  count(passage, structure, unit) %>%
  pivot_wider(
    names_from = passage,
    values_from = n,
    values_fill = 0
  ) %>%
  arrange(unit, structure) %>%
  relocate(structure, .after = unit) %>%
  rename(`Unit Type` = unit, 
         `Structure` = structure, 
         `Passage 1` = `1c`, 
         `Passage 2` = `2c`) %>%
  write_csv(file = "./structure_distribution.csv")


# Passage comparisons  

p1 <- passages %>%
  filter(passage == "1c")

p1_cl <- filter(p1, unit == "clause")
p1_ngp <- filter(p1, unit == "ngp")

p2 <- passages %>%
  filter(passage == "2c")

p2_cl <- filter(p2, unit == "clause")
p2_ngp <- filter(p2, unit == "ngp")


# Derive Hamming distance values for each pair of clauses per text
p1_cl_distances <- get_distances(p1_cl$structure_vector)
p2_cl_distances <- get_distances(p2_cl$structure_vector)
cl_distance_df <- rbind(tibble(passage = "1b", distances = p1_cl_distances), 
                     tibble(passage = "2b", distances = p2_cl_distances))

p1_ngp_distances <- get_distances(p1_ngp$structure_vector)
p2_ngp_distances <- get_distances(p2_ngp$structure_vector)
ngp_distance_df <- rbind(tibble(passage = "1b", distances = p1_ngp_distances), 
                        tibble(passage = "2b", distances = p2_ngp_distances))

# Get descriptive statistics

# range
# clause
p1_cl_distances %>% range
p1_cl$unit_size %>% range
p1_cl$word_count %>% range
p1_cl$max_layer_depth %>% range

p2_cl_distances %>% range
p2_cl$unit_size %>% range
p2_cl$word_count %>% range
p2_cl$max_layer_depth %>% range


# nominal group
p1_ngp_distances %>% range
p1_ngp$unit_size %>% range
p1_ngp$word_count %>% range
p1_ngp$max_layer_depth  %>% range


p2_ngp_distances %>% range
p2_ngp$unit_size %>% range
p2_ngp$word_count %>% range
p2_ngp$max_layer_depth %>% range

# mean
# clause
p1_cl_distances %>% mean
p1_cl$unit_size %>% mean
p1_cl$word_count %>% mean
p1_cl$max_layer_depth %>% mean

p2_cl_distances %>% mean
p2_cl$unit_size %>% mean
p2_cl$word_count %>% mean
p2_cl$max_layer_depth %>% mean

# nominal group
p1_ngp_distances %>% mean
p1_ngp$unit_size %>% mean
p1_ngp$word_count %>% mean
p1_ngp$max_layer_depth %>% mean

p2_ngp_distances %>% mean
p2_ngp$unit_size %>% mean
p2_ngp$word_count %>% mean
p2_ngp$max_layer_depth %>% mean

# Visualise descriptive statistics
flexplot(formula = unit_size ~ passage , data = passages)
flexplot(formula = word_count ~ passage , data = passages)
flexplot(formula = distances ~ passage , data = cl_distance_df)
flexplot(formula = distances ~ passage , data = ngp_distance_df)

# T-tests
# clause
t.test(p1_cl_distances, p2_cl_distances)
t.test(p1_cl$unit_size, p2_cl$unit_size)
t.test(p1_cl$word_count, p2_cl$word_count)
t.test(p1_cl$max_layer_depth, p2_cl$max_layer_depth)

# nominal group
t.test(p1_ngp_distances, p2_ngp_distances)
t.test(p1_ngp$unit_size, p2_ngp$unit_size)
t.test(p1_ngp$word_count, p2_ngp$word_count)
t.test(p1_ngp$max_layer_depth, p2_ngp$max_layer_depth)





