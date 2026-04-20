[] - brackets matchs the chars you include in
    example [02]
        will match any txt that have 0 or 2
    example [0-9]
        matches any text that have digits

{} - searches for occurrences:
    example[0]{2}
        will match the first 2 occurrences of 0
    example[0-9]{5}
        will match if have 6 digits or more -> if have more than 6, the first 6 digits will be the match

$ - represents the end of the line 
    invert the matchs from the end of a line to the beginning: (works like the python syntax list[::-1])
    example[0-9]{2}$: 403321
        the "21" will be the match for this regex

^ - represents the beginning of the line
    example ^[0-9]{4}$
        will match number with 4 digits

+ - represents any number of occurrences of a pattern (unlike {} that specifies the number of occurencies, + represents 0 occurrences or more)

() - make groups of patterns