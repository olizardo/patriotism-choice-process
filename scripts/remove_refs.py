with open('manuscript.tex', 'r') as f:
    content = f.read()

# Replace Figure refs
content = content.replace(r'Figure \ref{fig:logistic_pride}', 'Figure 1')
content = content.replace(r'Figure \ref{fig:pride_bar}', 'Figure 2')
content = content.replace(r'Figure \ref{fig:marginal_educ}', 'Figure 3')
content = content.replace(r'Figure \ref{fig:membership_forest}', 'Figure 4')

# Replace Table refs
content = content.replace(r'Table \ref{tab:nationalism}', 'Table 1')
content = content.replace(r'Table \ref{tab:educ}', 'Table 2')
content = content.replace(r'Table \ref{tab:full2004}', 'Table 3')

with open('manuscript.tex', 'w') as f:
    f.write(content)
