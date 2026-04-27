############################################################
# Poker Bot App Practice Lab - Ruth Hotaling
# Mathematics of Poker
#
# Format: R script with commented instructions
# Goal: work through core poker math, ranges, bot inputs,
#       and simple bot design in the poker bot project.
############################################################

############################################################
# PURPOSE
#
# In this lab you will work through three connected ideas that
# sit at the heart of the poker bot app:
#
# 1. Mathematical decision tools such as pot odds,
#    break-even equity, expected value, and regret.
# 2. Ranges and uncertainty, including Monte Carlo equity
#    and weighted opponent ranges.
# 3. Bot design, where you inspect the information available
#    to a bot and then modify a starter bot.
#
# The goal is not to build a perfect poker agent. The goal is
# to understand how mathematical quantities become inputs to
# decisions, and how those decisions are encoded in an R function.
############################################################

############################################################
# LEARNING GOALS
#
# By the end of this lab, you should be able to:
# - compute and interpret core poker quantities,
# - estimate hand equity using simulation,
# - represent a simple weighted range in R,
# - inspect the bot_input object passed to a bot,
# - modify a simple bot so that its actions depend on
#   mathematical information.
############################################################

############################################################
# SUGGESTED TIMING FOR A 90-MINUTE LAB
#
# Part 0. Setup                      5 minutes
# Part I. Core calculations         20 minutes
# Part II. Equity and ranges        25 minutes
# Part III. Inspecting bot input    15 minutes
# Part IV. Modifying a bot          20 minutes
# Wrap-up                            5 minutes
############################################################


############################################################
# Part 0. Setup
############################################################

# This lab file now lives in assignments_demos/.
# Run it from the poker bot project root, then load the project files.

source("poker_load_all.R")
poker_load_all(include_demos = TRUE)

# If your project folder is set correctly, this should load the
# engine, math functions, example bots, and demos.

# Files you will use today:
# - shared_helpers/poker_math.R: core mathematical calculations
# - shared_helpers/equity_tools.R: Monte Carlo equity tools
# - shared_helpers/quant_tools.R: range utilities and additional quantitative tools
# - core_internal/game_engine.R: the tournament and hand state engine
# - reference_bots/example_bots.R: sample bots
# - student_work/BotTemplate.R: a student-facing template for writing a bot


############################################################
# Part I. Core Poker Math
############################################################

# A bot does not directly "know" whether a play is good.
# Instead, it uses quantities that help evaluate decisions
# under uncertainty.


# 1. Pot odds and break-even equity
#
# Suppose the pot is 120 chips and you must call 40 chips.
# Run the code below. Then interpret the result.
#
# Question:
# What minimum equity do you need for a call to break even?
### We need 0.25 minimum equity (P/P+B)

pot_before_call <- 120
call_amount <- 40

pot_odds(call_amount, pot_before_call)


# Task 1
# Suppose the pot is 100 chips and you are considering a bluff
# of 75 chips. Run the code below.
#
# Then answer:
# What fold frequency does your opponent need to have for this
# bluff to break even?

pot_before_bet <- 100
bet_amount <- 75

break_even_fold_prob_bluff(pot_before_bet, bet_amount)

# Write your response here:
### Your opponent needs a fold frequency of 0.4285714
#


# 2. Expected value of a call
#
# Now suppose:
# - the pot is 150,
# - the amount to call is 50,
# - your equity when called is 0.35.
#
# Run the code below.

ev_call(equity = 0.35, call_amount = 50, pot_before_call = 150)

# Try a few values of equity and see how the output changes.

ev_call(equity = 0.20, call_amount = 50, pot_before_call = 150)
ev_call(equity = 0.30, call_amount = 50, pot_before_call = 150)
ev_call(equity = 0.40, call_amount = 50, pot_before_call = 150)

# Task 2
# At about what equity does the call become profitable?
# Compare your answer to the break-even equity from the pot odds
# calculation above.
#
# Write your response here:
####The call becomes profitable at equity 0.25
###Thus the pot odds give us the break-even equity (0.25)


# 3. Regret as a way to compare actions
#
# A bot may choose among several actions. One useful way to think
# is to compare the chosen action with the best available action.

ev_options <- c(fold = 0, call = 8, raise = 13)
ev_best_action(ev_options)
ev_regret(ev_options, chosen_action = "call")

# Task 3
# What is the regret of calling here?
# What does that regret mean in words?

# Write your response here:
###The regret of calling is 5
###This means that the player should've called more often because it's positive regret. But they didn't make bad decisions.


#Challenge: Create a new function mixed_regret which calculutes the regret of a mixed strategy for a given chosen_action

############################################################
# Part II. Equity and Ranges
############################################################

# Poker decisions depend on hidden information. Since we do not
# know the opponent's exact hand, we work with ranges and with
# equity against possible holdings.


# 4. Monte Carlo hand-vs-hand equity
#
# Here is a classic matchup: pocket aces against pocket kings.

hole_1 <- data.frame(
  rank = c("A", "A"),
  suit = c("h", "s"),
  card = c("Ah", "As"),
  stringsAsFactors = FALSE
)

hole_2 <- data.frame(
  rank = c("K", "K"),
  suit = c("h", "s"),
  card = c("Kh", "Ks"),
  stringsAsFactors = FALSE
)

holdem_equity_mc_fast(
  hole_list = list(hole_1, hole_2),
  n_sims = 500
)

# Task 4
# Record the approximate equity of each hand.
# Then rerun with n_sims = 50, 1000, and 50000.
#
# Questions:
# - What changes as the number of simulations increases?
# - What seems to stabilize?

holdem_equity_mc_fast(
  hole_list = list(hole_1, hole_2),
  n_sims = 50
)

holdem_equity_mc_fast(
  hole_list = list(hole_1, hole_2),
  n_sims = 500
)

holdem_equity_mc_fast(
  hole_list = list(hole_1, hole_2),
  n_sims = 1000
)

# Write your response here:
##### Equity when n_sims = 500: 1) 0.837; 2) 0.163
###             n_sims = 50: 1) 0.88; 2) 0.12
###             n_sims = 1000: 1) 0.831; 2) 0.169
###             n_sims = 50000: 1) 0.82497; 2) 0.17503
###As the number of simulations increase, the equity for player 1 gets marginally smaller and the equity for player 2 gets marginally larger.
###The equities themselves seem to stabilize, giving us a better picture of who is more likely to win. The numbers are closer together as the number of simulations increase.


# 5. Equity on a partial board
#
# Now suppose the flop is already known.

board_df <- data.frame(
  rank = c("A", "7", "2"),
  suit = c("d", "c", "h"),
  card = c("Ad", "7c", "2h"),
  stringsAsFactors = FALSE
)

holdem_equity_mc_fast(
  hole_list = list(hole_1, hole_2),
  board_df = board_df,
  n_sims = 500
)

# Task 5
# Why does Player 1's equity change so dramatically here?
# Use poker language if helpful, but be mathematically precise.
#
# Write your response here:
###Player 1's equity increases to 1 because they have pocket aces, which will almost always beat pocket kings on this board



# 6. Weighted ranges
#
# A range is a collection of possible hands together with weights.
# In this project, a simple Hold'em range can be built with
# new_range_holdem().

example_range <- new_range_holdem(
  data.frame(
    c1 = c("Ah", "Ks", "Qh"),
    c2 = c("Kd", "Qc", "Qs"),
    w  = c(3, 2, 1)
  ),
  label = "Example weighted range"
)

example_range
example_range$combos
sum(example_range$weights)

# Notice that the weights are normalized automatically.

# Task 6
# Explain what it means that the weights are normalized.
# Why might weighted ranges be more realistic than treating every
# possible hand as equally likely?
#
# Write your response here:
###Weighted ranges may be more realistic because players do not choose all hands with equal frequency. Their choices depend on
###strategy, position, and their style of play.


# 7. Build your own simple range
#
# Create a range meant to represent a very strong preflop raising
# range. Use 6 specific two-card combinations and give larger
# weights to the strongest hands.

strong_range <- new_range_holdem(
  data.frame(
    c1 = c("Ah", "As", "Kh", "Ad"),
    c2 = c("Ac", "Kd", "Ks", "Kc"),
    w  = c(4, 4, 3, 2)
  ),
  label = "Strong opening range"
)

strong_range$combos
strong_range$weights

# Here is an example of using holdem_equity_mc_fast() with a range
# on one seat and a fixed hand on another seat.

opponent_range <- new_range_holdem(
  data.frame(
    c1 = c("Kh", "Qs", "Jd"),
    c2 = c("Kd", "Qc", "Jh"),
    w  = c(3, 2, 1)
  ),
  label = "Opponent range"
)

hero_hand <- data.frame(
  rank = c("A", "K"),
  suit = c("h", "d"),
  stringsAsFactors = FALSE
)

holdem_equity_mc_fast(list(hero_hand, opponent_range), n_sims = 500)

# Task 7
# Modify the example above to create:
# - a tight range
# - a loose range
#
# Then compare the size and weight distribution of the two ranges.
# After that, test range-versus-range equity on various boards.

tight_range <- new_range_holdem(
  data.frame(
    c1 = c("Ah", "Kh", "Qh", "Jh"),
    c2 = c("Ad", "Kd", "Qd", "Jd"),
    w  = c(5, 4, 3, 2)
  ),
  label = "Tight range"
)

loose_range <- new_range_holdem(
  data.frame(
    c1 = c("Ah", "Kh", "Qh", "Jh", "Th", "9h"),
    c2 = c("Ad", "Kd", "Qd", "Jd", "Td", "9d"),
    w  = c(3, 3, 2, 2, 1, 1)
  ),
  label = "Loose range"
)

#tight_range <- strong_range
#loose_range <- strong_range

range_size(tight_range)
range_size(loose_range)

tight_range$combos
loose_range$combos

# Optional place to test range-vs-range equity.
# Replace these with your own ranges once you build them.

holdem_equity_mc_fast(list(tight_range, loose_range), n_sims = 500)

# Write your response here:
###Tight range has fewer combinations and focuses on strong hands
###Loose range has more combinations and spreads weight across many hands
###Tight range has a higher equity due to its stronger hands

##Try with a different board that will favor a loose range:
loose_board <- data.frame(
  rank = c("9", "T", "J"),
  suit = c("h", "d", "c"),
  stringsAsFactors = FALSE
)

holdem_equity_mc_fast(list(tight_range, loose_range), board = loose_board, n_sims = 500)


# 8. Ranges from strings
#
# These functions let you build ranges from text strings similar to
# what you might copy from an online range tool.

expand_range_string_to_classes("77-JJ")
expand_range_string_to_classes("A5s-A2s")
expand_range_string_to_classes("KQo-KTo")

r1 <- new_range_holdem_from_string("77-JJ, A5s-A2s, KQo-KTo")
r2 <- new_range_holdem_from_string("QQ+, AKs, AKo")

holdem_equity_mc_fast(list(r1, r2), n_sims = 500)

# Task 8
# Create two additional range strings of your own and compare them. Hint you can use poker-tools
# to construct the range and then copy in the hands. You will likely need to add quotes
# Try at least one comparison on a specific flop.
#
# Example starting point for a fixed flop:

flop_board <- data.frame(
  rank = c("K", "T", "4"),
  suit = c("h", "h", "c"),
  card = c("Kh", "Th", "4c"),
  stringsAsFactors = FALSE
)

holdem_equity_mc_fast(list(r1, r2), board_df = flop_board, n_sims = 500)

# Write your response here:

flop_board2 <- data.frame(
  rank = c("J", "T", "7"),
  suit = c("h", "d", "c"),
  card = c("Jh", "Td", "7c"),
  stringsAsFactors = FALSE
)

expand_range_string_to_classes("99-AA")
expand_range_string_to_classes("73s-76s")
expand_range_string_to_classes("Q2o-QTo")

expand_range_string_to_classes("22-55")
expand_range_string_to_classes("52o-54o")
expand_range_string_to_classes("A2s-AKs")

r3 <- new_range_holdem_from_string("99-AA, 73s-76s, Q2o-QTo")
r4 <- new_range_holdem_from_string("22-55, 52o-54o, A2s-AKs")

holdem_equity_mc_fast(list(r3, r4), board_df = flop_board2, n_sims = 500)

# 9. Board texture features
#
# The project also includes simple board-texture tools.

flop_df <- data.frame(
  rank = c("K", "T", "4"),
  suit = c("h", "h", "c"),
  stringsAsFactors = FALSE
)

board_features(flop_df)

# Task 9
# Inspect the output.
# Which pieces of this output might be useful to a bot deciding
# whether to bet the flop?
#
# Write your response here:
###Some useful pieces of this output are connectivity which could indicate a straight, paired vs. unpaired boards,
###high card presence, and the two-tone output which can indicate if a flush is possible.
###All of the outputs are useful to understand and decide on betting.


############################################################
# Part III. What Information Does a Bot Actually Receive?
############################################################

# A poker bot does not see the whole tournament state directly.
# It is given a structured object called bot_input.


# 10. Create a live tournament state
#
# We will initialize a small tournament, start a hand, and inspect
# the current acting player's input.

bot_fns <- list(
  "Random Bot" = random_bot,
  "Caller Bot" = always_call_bot,
  "Passive Bot" = passive_bot
)

tourn <- initialize_tournament(
  bot_fns = bot_fns,
  player_names = names(bot_fns),
  starting_stack = 1000
)

tourn <- initialize_hand(tourn)
tourn <- post_blinds_and_antes(tourn)

# Now build the input that the acting bot will receive.

bot_input_example <- build_bot_input(tourn)
str(bot_input_example, max.level = 2)

# You can also view it as a data frame.

demo_show_bot_input(tourn)

# Task 10
# Find and record the following pieces of information inside

#Write your response here:
# bot_input_example:
# - your hole cards: Td, 8c
# - the current pot: 150
# - the current street: preflop
# - the legal actions: fold, call, raise
# - your current stack: 1000
# - the public information about the other players: their seat position, stack size, if they are active or if they have folded,
#if they are all in, how much they've committed this round and this hand, the blind sizes. Their hold cards are not included.


# 11. Explore the legal action structure

bot_input_example$legal_actions
bot_input_example$legal_actions$legal_action_types
bot_input_example$legal_actions$actions

# Task 11
# Why is it important for a bot to check which actions are legal
# before returning an action?
#
# Write your response here:
###It's important for a bot to check which actions are legal before returning an action because an illegal action could cause
###the bot to return an error or behave unpredictably. Check if actions are legal allows the bot to produce valid decisions.


############################################################
# Part IV. Reading and Modifying a Bot
############################################################

# 12. Read a starter bot
#
# Open reference_bots/example_bots.R and locate the function
# simple_preflop_strength_bot().
#
# This bot does something simple:
# - if it is preflop and it likes its hand, it plays aggressively,
# - otherwise it falls back to checking or calling when possible.

# Task 12
# Read the function and answer:
# 1. What counts as a "premium" hand in this bot?
# 2. What does the bot do with premium hands?
# 3. What does it do after the flop?
#
# Write your response here:
###A premium hand is either paired, contains only Q's and above, or has one ace and the other card is at least a Ten
###If the bot has a premium hand, it plays aggressively. First tries to raise, and if not allowed then tries to bet, and if not allowed then tries to go all-in. If none of these are possible, it will call, check, or fold.
###After the flop the bot become passive and will either check, call, or fold (in that order). It ignores hand strength.


# 13. Try a starter template
#
# Open student_work/BotTemplate.R. You should see a function called my_bot_name()
# and helper functions such as:
# - bot_has_action()
# - bot_min_bet()
# - bot_min_raise()
# - choose_preferred_action()
#
# These help keep your bot legal and readable.


# 14. Build a simple math-based bot
#
# Create a new bot that follows this rule:
#
# Preflop:
# - raise minimum with pairs, ace-king, or ace-queen,
# - otherwise check if possible,
# - otherwise call if the call is at most one big blind,
# - otherwise fold.
#
# Postflop:
# - check when possible,
# - otherwise call only if the break-even equity threshold is at
#   most 0.25,
# - otherwise fold.
#### Challenge have your bot estimate the equity of your hand, versus some pre-set range for villain.
#### Have it call a bet only if the estimated equity exceeds the pot odds.
# The starter version is below.

lab_bot <- function(bot_input) {
  legal_types <- bot_input$legal_actions$legal_action_types
  hole_cards <- bot_input$hole_cards
  street <- bot_input$street
  big_blind <- bot_input$big_blind
  pot <- bot_input$pot
  current_bet <- bot_input$current_bet
  committed <- bot_input$committed_this_round

  call_amount <- max(0, current_bet - committed)
  vals <- sort(hole_rank_values(hole_cards), decreasing = TRUE)

  if (street == "preflop" && length(vals) == 2) {
    paired <- vals[1] == vals[2]
    ak <- identical(vals, c(14, 13))
    aq <- identical(vals, c(14, 12))

    if (paired || ak || aq) {
      if (bot_has_action(bot_input, "raise")) {
        return(list(type = "raise", amount = bot_min_raise(bot_input)))
      }
      if (bot_has_action(bot_input, "bet")) {
        return(list(type = "bet", amount = bot_min_bet(bot_input)))
      }
    }

    if ("check" %in% legal_types) {
      return(list(type = "check"))
    }

    if ("call" %in% legal_types && call_amount <= big_blind) {
      return(list(type = "call"))
    }

    return(list(type = "fold"))
  }

  if ("check" %in% legal_types) {
    return(list(type = "check"))
  }

  if ("call" %in% legal_types) {
    threshold <- pot_odds(call_amount, pot)
    if (threshold <= 0.25) {
      return(list(type = "call"))
    }
  }

  list(type = "fold")
}

lab_bot_challenge.14 <- function(bot_input) {
  legal_types <- bot_input$legal_actions$legal_action_types
  hole_cards <- bot_input$hole_cards
  street <- bot_input$street
  big_blind <- bot_input$big_blind
  pot <- bot_input$pot
  current_bet <- bot_input$current_bet
  committed <- bot_input$committed_this_round
  board <- bot_input$board

  call_amount <- max(0, current_bet - committed)
  vals <- sort(hole_rank_values(hole_cards), decreasing = TRUE)

  if (street == "preflop" && length(vals) == 2) {
    paired <- vals[1] == vals[2]
    ak <- identical(vals, c(14, 13))
    aq <- identical(vals, c(14, 12))

    if (paired || ak || aq) {
      if (bot_has_action(bot_input, "raise")) {
        return(list(type = "raise", amount = bot_min_raise(bot_input)))
      }
      if (bot_has_action(bot_input, "bet")) {
        return(list(type = "bet", amount = bot_min_bet(bot_input)))
      }
    }

    if ("check" %in% legal_types) {
      return(list(type = "check"))
    }

    if ("call" %in% legal_types && call_amount <= big_blind) {
      return(list(type = "call"))
    }

    return(list(type = "fold"))
  }

  if ("check" %in% legal_types) {
    return(list(type = "check"))
  }

  if ("call" %in% legal_types) {

    # Estimate pot odds
    threshold <- pot_odds(call_amount, pot)

    villain_range <- new_range_holdem(
      data.frame(
        c1 = c("Ah", "Kh", "Qh", "Jh"),
        c2 = c("Ad", "Kd", "Qd", "Jd"),
        w  = c(3, 3, 2, 2)
      ),
      label = "Default villain range"
    )

    hero_hand_df <- data.frame(
      rank = substring(hole_cards, 1, 1),
      suit = substring(hole_cards, 2, 2),
      stringsAsFactors = FALSE
    )

    equity_result <- holdem_equity_mc_fast(
      list(hero_hand_df, villain_range),
      board = board,
      n_sims = 300
    )

    hero_equity <- equity_result[1]

    if (hero_equity >= threshold) {
      return(list(type = "call"))
    }
  }

  list(type = "fold")
}

# Task 13
# Explain the line below in words:
#
#   threshold <- pot_odds(call_amount, pot)
#
# What quantity is the bot calculating?
# What is it using that threshold for?
#
# Write your response here:
###The bot is calculating the pot odds which represent the minimum equity that the bot needs in order to make calling the bet profitable. It is calculating the breakeven equity.
###It is using that threshold to decide if calling is going to be profitable and mathematically justified.


# 15. Test your bot on a live input
#
# Replace one of the bots in the tournament with your new bot.

bot_fns_test <- list(
  "Lab Bot" = lab_bot_challenge.14,
  "Random Bot" = random_bot,
  "Caller Bot" = always_call_bot
)

tourn2 <- initialize_tournament(
  bot_fns = bot_fns_test,
  player_names = names(bot_fns_test),
  starting_stack = 500
)

tourn2 <- initialize_hand(tourn2)
tourn2 <- post_blinds_and_antes(tourn2)

bot_input_test <- build_bot_input(tourn2)
demo_show_bot_input(tourn2)
lab_bot_challenge.14(bot_input_test)

# Task 14
# Run this section several times by re-initializing the tournament.
# Does your bot always return a legal action?
# Describe one situation where your bot raises, one where it calls,
# and one where it folds.
#
# Write your response here:
###Yes, my bot always returns a legal action
###A situation where my bot raises is preflop when dealt a strong hand (pair, AQ, AK) and raising is allowed.
###A situation where my bot calls is postflop when there is a bet and calling is allowed and equity is greater than or equal to the pot odds threshold.
###A situation where by bot folds is if it faces a bet postflop and its equity is lower than the pot odds threshold.


# 16. challenge: make the bot more thoughtful
#
# Revise lab_bot() so that it also uses board texture on the flop.
# For example, you might decide that on the flop the bot should:
# - bet when checked to on dry boards,
# - check more often on coordinated two-tone boards,
# - call less often when the required equity threshold is large.
#
# A starter idea is below.

lab_bot_v2_starter <- function(bot_input) {
  legal_types <- bot_input$legal_actions$legal_action_types
  board <- bot_input$board
  street <- bot_input$street
  pot <- bot_input$pot
  current_bet <- bot_input$current_bet
  committed <- bot_input$committed_this_round
  call_amount <- max(0, current_bet - committed)

  if (street == "flop" && length(board) == 3) {
    board_df <- parse_cards(board)
    feats <- board_features(board_df)

    if ("bet" %in% legal_types && !isTRUE(feats$two_tone) && feats$connectivity <= 1) {
      return(list(type = "bet", amount = bot_min_bet(bot_input)))
    }
  }

  if ("check" %in% legal_types) {
    return(list(type = "check"))
  }

  if ("call" %in% legal_types) {
    threshold <- pot_odds(call_amount, pot)
    if (threshold <= 0.20) {
      return(list(type = "call"))
    }
  }

  list(type = "fold")
}

lab_bot_v2 <- function(bot_input) {
  legal_types <- bot_input$legal_actions$legal_action_types
  hole_cards <- bot_input$hole_cards
  board <- bot_input$board
  street <- bot_input$street
  pot <- bot_input$pot
  current_bet <- bot_input$current_bet
  committed <- bot_input$committed_this_round

  call_amount <- max(0, current_bet - committed)

  vals <- sort(hole_rank_values(hole_cards), decreasing = TRUE)

  if (street == "preflop" && length(vals) == 2) {
    paired <- vals[1] == vals[2]
    ak <- identical(vals, c(14, 13))
    aq <- identical(vals, c(14, 12))

    if (paired || ak || aq) {
      if ("raise" %in% legal_types) {
        return(list(type = "raise", amount = bot_min_raise(bot_input)))
      }
      if ("bet" %in% legal_types) {
        return(list(type = "bet", amount = bot_min_bet(bot_input)))
      }
    }

    if ("call" %in% legal_types && call_amount <= big_blind) {
      return(list(type = "call"))
    }

    if ("check" %in% legal_types) {
      return(list(type = "check"))
    }

    return(list(type = "fold"))
  }

  if (street == "flop" && length(board) == 3) {

    board_df <- parse_cards(board)
    feats <- board_features(board_df)

    # Compute a simple "texture score"
    dry_board <- (!feats$two_tone && feats$connectivity <= 1)
    very_wet  <- (feats$two_tone && feats$connectivity >= 2)

    # If checked to
    if ("check" %in% legal_types) {

      # Bet dry boards aggressively
      if (dry_board && "bet" %in% legal_types) {
        return(list(type = "bet", amount = bot_min_bet(bot_input)))
      }

      # Check back on wet boards more often
      return(list(type = "check"))
    }

    # If facing a bet
    if ("call" %in% legal_types) {

      threshold <- pot_odds(call_amount, pot)

      # looser calls on dry boards, tighter on wet boards
      equity_buffer <- if (dry_board) 0.05 else if (very_wet) -0.05 else 0

      hero_equity <- 0.5  # fallback baseline if no equity model used

      if ((hero_equity + equity_buffer) >= threshold) {
        return(list(type = "call"))
      }
    }

    return(list(type = "fold"))
  }

  if ("check" %in% legal_types) {
    return(list(type = "check"))
  }

  if ("call" %in% legal_types) {
    threshold <- pot_odds(call_amount, pot)

    if (threshold <= 0.25) {
      return(list(type = "call"))
    }
  }

  return(list(type = "fold"))
}

# Task 15
# Modify this bot and explain your design choices.
###Modified bot above
# Write your response here:
###My design consisted of the same preflop action from the previous question, utilized board texture to bet aggressively on dry flops,
###more cautious play on coordinated/two-tone boards, and calls are now slightly adjusted based on texture and not based purely on pot odds.


# Demo Tournament with lab_bot
#
# After revising lab_bot(), you can test it in a small tournament
# against a few of the sample bots.

source("poker_load_all.R")
poker_load_all(include_demos = TRUE, verbose = FALSE)

demo_result <- run_tournament(
  bot_fns = list(
    lab_bot_v2,
    random_bot,
    always_call_bot,
    passive_bot,
    aggressive_bot
  ),
  player_names = c(
    "Lab Bot",
    "Random Bot",
    "Caller Bot",
    "Passive Bot",
    "Aggro Bot"
  ),
  starting_stack = 2500,
  tournament_id = "LAB_BOT_DEMO",
  rng_seed = 123,
  max_hands = 200,
  verbose = TRUE
)

data.frame(
  player = vapply(demo_result$players, function(p) p$name, character(1)),
  chips = vapply(demo_result$players, function(p) p$stack, numeric(1)),
  place = vapply(demo_result$players, function(p) p$finishing_place, integer(1))
)[order(
  vapply(demo_result$players, function(p) p$finishing_place, integer(1))
), ]

# If you want a fairer comparison, run the tournament several times
# with different rng_seed values and compare your bot's average
# finishing place.


############################################################
# Wrap-Up Questions
############################################################

# 17. Math to code
# Which part of today's lab felt most clearly mathematical,
# and which part felt most like programming?
# How did the two interact?
#
# Write your response here:
###Calculating pot odds and using that to interpret decisions felt the most clearly mathematical as we I have done that several times in class/in homework.
###Programming the bots felt the most like programming because of the logic and for loops, and coding syntax, etc.
###The two interacted by working with each other to create a larger tool for poker.


# 18. Limits of the current bots
# What is one important piece of information that your bot does not
# currently use, but probably should use in a more serious version?
#
# Write your response here:
###One important piece of information that a bot could use is accounting for random error or in poker terms, accounting for a player
###making a rash decision or a decision that isn't necessarily mathematically correct. The bot could choose some things randomly sometimes to account for human behavior.

# 19. Reflection
# A poker bot acts under uncertainty and with limited information.
# Give one example from today's lab where the bot had to rely on a
# model or approximation rather than exact knowledge.
#
# Write your response here:
###The bot had to rely on a model or approximation rather than exact knowledge when dealing with ranges instead of exact hands.
###If the bot doesn't know other's hands, it has to calculate equity based on ranges, which isn't completely mathematically precise. Especially when dealing with humans.

