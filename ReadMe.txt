Usage
=====

To run this program you will need ruby installed and can run it via the command line as such below.
The output is written to output.txt. The program reads from the users.json and companies.json files
in the current working directory. All other requirements are as described in challenge.txt

ruby challenge.db

Assumptions
===========
* There was no specification on how to handle errors so I assumed that I should:
  * Print critical errors and raise the exception ending the program with as much information as possible
  * Print an error message and try to recover from things that might allow us to continue processing.
    This could include things like one user missing/invalid fields
* I assumed company IDs had to be unique and that using multiple with the same ID would be invalid. 
  When this happens I just ignore the second company.
* I assumed it was ok for users to have the same id and name/email. As such this is not validated but
  could be in a different system with stricter requirements

Notes
=====
* This was my first time coding in Ruby and had to learn it for this challenge. I apologize if 
  some of the syntax was not ruby best practices but tried to make sure i docuemented and keep
  the code as clean as I could for my first time
* The test directory contains some sample test files that I used to test the program if you want to have a look