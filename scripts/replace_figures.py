import re

with open('manuscript.tex', 'r') as f:
    content = f.read()

# Replace Figure 1
content = re.sub(
    r'\\begin\{figure\}\[H\]\n\\centering\n\\includegraphics\[width=1\.0\\textwidth\]\{Plots/fig-logistic-pride\.pdf\}\n\\caption\{Increase in Likelihood of Being `Very Proud\' Post-9/11 \(Odds Ratios\)\}\n\\label\{fig:logistic_pride\}\n\\end\{figure\}',
    r'\\begin{center}\n\\textbf{[Insert Figure 1 about here]}\n\\end{center}',
    content
)

# Replace Figure 2
content = re.sub(
    r'\\begin\{figure\}\[H\]\n\\centering\n\\includegraphics\[width=0\.8\\textwidth\]\{Plots/fig-pride-bar\.pdf\}\n\\caption\{Distribution of U\.S\. Pride Scale Scores \(1996 vs\. 2004\)\}\n\\label\{fig:pride_bar\}\n\\end\{figure\}',
    r'\\begin{center}\n\\textbf{[Insert Figure 2 about here]}\n\\end{center}',
    content
)

# Replace Figure 3
content = re.sub(
    r'\\begin\{figure\}\[H\]\n\\centering\n\\includegraphics\[width=0\.8\\textwidth\]\{Plots/fig-marginal-educ\.pdf\}\n\\caption\{Predicted U\.S\. Pride Score across Education Levels by Year\}\n\\label\{fig:marginal_educ\}\n\\end\{figure\}',
    r'\\begin{center}\n\\textbf{[Insert Figure 3 about here]}\n\\end{center}',
    content
)

# Replace Figure 4
content = re.sub(
    r'\\begin\{figure\}\[H\]\n\\centering\n\\includegraphics\[width=1\.0\\textwidth\]\{Plots/fig-membership-forest\.pdf\}\n\\caption\{Effect of Specific Association Memberships on U\.S\. Pride \(Controlling for Cohort\)\}\n\\label\{fig:membership_forest\}\n\\end\{figure\}',
    r'\\begin{center}\n\\textbf{[Insert Figure 4 about here]}\n\\end{center}',
    content
)

with open('manuscript.tex', 'w') as f:
    f.write(content)

