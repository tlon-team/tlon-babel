;;; tlon-bae.el --- A collection of convenience functions for the Tlön BAE project. -*- lexical-binding: t -*-

;; Author: Pablo Stafforini
;; Maintainer: Pablo Stafforini
;; Version: 0.1.0
;; Homepage: https://tlon.team
;; Keywords: convenience tools


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;;; Code:
(require 'org)
(require 'cl-lib)
(require 'github-review)

(defun tlon-bae-format-file (&optional extension tag)
  "Return a file name based on user supplied information.
If EXTENSION is not provided, markdown is used."
  (let* ((lastname (if tag "tag" (read-string "Last name(s) [separated by spaces if more than one author]: ")))
	 (title (read-string "Title: "))
	 (slug-lastname (tlon-core-slugify lastname))
	 (slug-title (tlon-core-slugify title))
	 (extension (or extension "md")))
    (cl-values (file-name-with-extension (concat slug-lastname "--" slug-title) extension)
	       lastname
	       title)))

(defun tlon-bae-rename-file (&optional extension)
  "Rename file at point based on user-supplied information.
If EXTENSION is not provided, markdown is used."
  (interactive)
  (let* ((source-file-path (dired-get-filename))
	 (file (cl-nth-value 0 (tlon-bae-format-file extension))))
    (rename-file
     source-file-path
     (file-name-concat
      (file-name-directory source-file-path)
      file)))
  (revert-buffer))

(defun tlon-bae-create-file (&optional extension)
  "Create a new file based on user-supplied information.
Prompt the user for bibliographic information and create a new
 file based on it in the current directory. If EXTENSION is not
 provided, markdown is used."
  (interactive)
  (let ((file (cl-nth-value 0 (tlon-bae-format-file extension))))
    (find-file file)))

(defvar tlon-bae-markdown-eawiki-footnote-source
  "\\[\\^\\[\\\\\\[\\([[:digit:]]\\{1,2\\}\\)\\\\\\]\\](#.+?)\\^\\]{#.+? .footnote-reference role=\"doc-noteref\"}"
  "Regexp to match footnotes in the main body.")

(defvar tlon-bae-markdown-eawiki-footnote-source2
  "\\[\\^\\[\\\\\\[\\([[:digit:]]\\)\\\\\\]\\](#.+?)\\^\\]{#\\\\\\\\\\\\\".+?\\\\\\\\\\\\\" .\\\\\\\\\\\\\\\"footnote-reference\\\\\\\\\\\\\" role=\"\\\\\\\\\\\\\"doc-noteref\\\\\\\\\\\\\"\"}"
  "Regexp to match footnotes in the main body.")

(defvar tlon-bae-markdown-eawiki-footnote-target
  "\\([[:digit:]]\\{1,2\\}\\). *?\\[\\[^\\*\\*\\[\\\\^\\](#.+?)\\*\\*^\\]{\\.footnote-back-link}\\]{#.+?}

    ::: footnote-content"

  "Regexp to match footnotes in the footnote section.")

(defvar tlon-bae-markdown-eawiki-footnote-target2
  "\\([[:digit:]]\\{1,2\\}\\)\\. *?\\[\\[^\\*\\*\\[\\\\^\\](#.+?)\\*\\*^\\]{\..+?}\\]{#.+?}

    ::: footnote-content "
  "Regexp to match footnotes in the footnote section.")

(defvar tlon-bae-markdown-eawiki-footnote-target3
  "\\([[:digit:]]\\{1,2\\}\\)\\. *?\\[\\[\\^\\*\\*\\[\\\\\\^\\](\\\\%22#.+?\\\\%22)\\*\\*\\^\\]{\\.\\\\\\\\\\\\\"footnote-back-link\\\\\\\\\\\\\"}\\]{#\\\\\\\\\\\\\\\".+?\\\\\\\\\\\\\\\"}

    ::: \\\\\"footnote-content\\\\\" "
  "Regexp to match footnotes in the footnote section.")

(defvar tlon-bae-markdown-eawiki-footnote-target4
  "\\([[:digit:]]\\{1,2\\}\\)\\. *?\\[\\[^\\*\\*\\[\\\\^\\](.+?)\\*\\*^\\]\\]{#.+?}

    footnote-content "
  "Regexp to match footnotes in the footnote section.")

(defvar tlon-bae-markdown-eawiki-footnote-target5
  "\\([[:digit:]]\\{1,2\\}\\)\\. *?\\[\\[^\\*\\*\\[\\\\^\\](#.+?)\\*\\*^\\]\\]{#.+?}

    footnote-content "
  "Regexp to match footnotes in the footnote section.")

(defvar tlon-markdown-eawiki-links
  "\\[\\(.+?\\)\\](\\\\%22\\(.+?\\)\\\\%22)"
  "Regexp to match links.")

(defvar tlon-markdown-eawiki-escaped-quotes
  "\\\\\\\\\\\\\""
  "Regexp to match escaped quotes.")

(defun tlon-bae-markdown-eawiki-cleanup (&optional buffer)
  "Cleanup the buffer visiting an EA Wiki entry.
Assumes that the entry was imported using the GraphQL query below
and converted to Markdown with Pandoc using `pandoc -s
[source.html] -t markdown -o [destination.md]'.

`{
  tag(input:{selector:{slug:\"[slug]\"}}) {
    result {
      name
      description {
	html
      }
      parentTag {
	name
      }
    }
  }
}'"
  (interactive)
  (when (not (eq major-mode 'markdown-mode))
    (user-error "Not in a Markdown buffer"))
  (save-excursion
    (unfill-region (point-min) (point-max))
    (goto-char (point-min))
    (while (re-search-forward "{.underline}" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "{.footnote-back-link}" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-source nil t)
      (replace-match (format "[^%s] " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-source2 nil t)
      (replace-match (format "[^%s]: " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-target nil t)
      (replace-match (format "[^%s]: " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-target2 nil t)
      (replace-match (format "[^%s]: " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-target3 nil t)
      (replace-match (format "[^%s]: " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-target4 nil t)
      (replace-match (format "[^%s]: " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-bae-markdown-eawiki-footnote-target5 nil t)
      (replace-match (format "[^%s]: " (match-string 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-markdown-eawiki-links nil t)
      (replace-match (format "[%s](%s)" (match-string 1) (match-string 2)) nil t))
    (goto-char (point-min))
    (while (re-search-forward tlon-markdown-eawiki-escaped-quotes nil t)
      (replace-match "\""))
    (goto-char (point-min))
    (while (re-search-forward " " nil t)
      (replace-match " "))
    (goto-char (point-min))
    (while (re-search-forward " :::" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "{.underline}" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "{.footnote-back-link}" nil t)
      (replace-match ""))
    (fill-region (point-min) (point-max))
    (save-buffer)
    ))

(defun tlon-convert-to-markdown ()
  "Convert a file from EA Wiki to Markdown."
  (interactive)
  (dolist (file (directory-files "." nil "\\.md$"))
    ;; (shell-command (format "pandoc -s '%s' -t markdown -o '%s'"
    ;; file
    ;; (file-name-with-extension file "md")))
    (with-current-buffer (find-file-noselect (file-name-with-extension file "md"))
      (message "Cleaning up %s" (buffer-name))
      (tlon-bae-markdown-eawiki-cleanup))))

(defvar tlon-bae-eawiki-slugs '("tag--impact"
				"tag--1day-sooner"
				"tag--80-000-hours"
				"tag--80-000-hours-podcast"
				"tag--ai-alignment-forum"
				"tag--ai-impacts"
				"tag--ai-safety-camp"
				"tag--ai-safety-support"
				"tag--ai-alignment"
				"tag--ai-forecasting"
				"tag--ai-governance"
				"tag--ai-interpretability"
				"tag--ai-race"
				"tag--ai-risk"
				"tag--ai-safety"
				"tag--ai-safety-resources-and-materials"
				"tag--ai-skepticism"
				"tag--ai-takeoff"
				"tag--allfed"
				"tag--abdul-latif-jameel-poverty-action-lab"
				"tag--academia-1"
				"tag--accidental-harm"
				"tag--adjusted-life-year"
				"tag--against-malaria-foundation"
				"tag--aging-research"
				"tag--aid-and-paternalism"
				"tag--air-pollution"
				"tag--albert-schweitzer-foundation"
				"tag--aligned-ai"
				"tag--alignment-research-center"
				"tag--alignment-tax"
				"tag--all-party-parliamentary-group-for-future-generations"
				"tag--altruistic-coordination"
				"tag--altruistic-motivation"
				"tag--altruistic-wager"
				"tag--ambition"
				"tag--anders-sandberg"
				"tag--andreas-mogensen"
				"tag--anima-international"
				"tag--animal-advocacy-careers"
				"tag--animal-ask"
				"tag--animal-charity-evaluators"
				"tag--animal-ethics"
				"tag--animal-welfare-fund"
				"tag--animal-product-alternatives"
				"tag--animal-sentience"
				"tag--animal-welfare"
				"tag--anthropic"
				"tag--anthropics"
				"tag--anthropogenic-existential-risk"
				"tag--antibiotic-resistance"
				"tag--antitrust-law"
				"tag--application-announcements"
				"tag--applied-ethics"
				"tag--april-fools-day-1"
				"tag--arb"
				"tag--architecture"
				"tag--armed-conflict"
				"tag--artificial-intelligence"
				"tag--artificial-sentience"
				"tag--asia"
				"tag--ask-me-anything"
				"tag--assistants"
				"tag--asteroids"
				"tag--astronomical-waste"
				"tag--asymmetry"
				"tag--atomically-precise-manufacturing"
				"tag--audio"
				"tag--automation"
				"tag--autonomous-weapon"
				"tag--axiology"
				"tag--ballot-initiative"
				"tag--bayes-theorem"
				"tag--bayesian-epistemology"
				"tag--berkeley-existential-risk-initiative"
				"tag--biodiversity-loss"
				"tag--bioethics"
				"tag--biosecurity"
				"tag--biosecurity-and-pandemics"
				"tag--biosurveillance"
				"tag--biotechnology"
				"tag--bitcoin"
				"tag--blockchain-technology"
				"tag--blogging"
				"tag--books"
				"tag--bostrom-apology"
				"tag--bounty-closed"
				"tag--bounty-open"
				"tag--brain-computer-interfaces"
				"tag--brian-tomasik"
				"tag--broad-vs-narrow-interventions"
				"tag--bryan-caplan"
				"tag--building-effective-altruism"
				"tag--building-the-field-of-ai-safety"
				"tag--burden-of-disease"
				"tag--covid-19-pandemic"
				"tag--california-effect"
				"tag--cambridge-existential-risks-initiative"
				"tag--career-advising"
				"tag--career-capital"
				"tag--career-choice"
				"tag--career-framework"
				"tag--carl-shulman"
				"tag--carrick-flynn"
				"tag--cash-transfers"
				"tag--cause-exploration-prizes"
				"tag--cause-innovation-bootcamp"
				"tag--cause-x"
				"tag--cause-candidates"
				"tag--cause-neutrality"
				"tag--cause-prioritization"
				"tag--center-for-applied-rationality"
				"tag--center-for-election-science"
				"tag--center-for-human-compatible-artificial-intelligence"
				"tag--center-for-reducing-suffering"
				"tag--center-on-long-term-risk"
				"tag--centre-for-effective-altruism-1"
				"tag--centre-for-enabling-ea-learning-and-research"
				"tag--centre-for-long-term-resilience"
				"tag--centre-for-the-governance-of-ai"
				"tag--centre-for-the-study-of-existential-risk"
				"tag--certificate-of-impact"
				"tag--charity-entrepreneurship"
				"tag--charity-science-foundation"
				"tag--charity-evaluation"
				"tag--charity-incubation"
				"tag--charter-cities"
				"tag--chatgpt"
				"tag--china"
				"tag--civilizational-collapse"
				"tag--classic-repost"
				"tag--classical-utilitarianism"
				"tag--climate-change"
				"tag--climate-engineering"
				"tag--cluelessness"
				"tag--cluster-headache"
				"tag--coaching"
				"tag--cognitive-bias"
				"tag--cognitive-decline"
				"tag--cognitive-enhancement"
				"tag--collections-and-resources"
				"tag--college-advice"
				"tag--communities-adjacent-to-effective-altruism"
				"tag--community"
				"tag--community-builder-writing-contest"
				"tag--community-epistemic-health"
				"tag--community-experiences"
				"tag--community-housing"
				"tag--community-infrastructure"
				"tag--community-projects"
				"tag--compassion-in-world-farming"
				"tag--competitive-debating"
				"tag--compute-governance"
				"tag--conferences"
				"tag--conflicts-of-interest"
				"tag--conjecture"
				"tag--conjunctive-vs-disjunctive-risk-models"
				"tag--consciousness-research"
				"tag--consequences-of-ai-timelines"
				"tag--consequentialism"
				"tag--conservation"
				"tag--constraints-on-effective-altruism"
				"tag--consultancy"
				"tag--cooperative-ai-1"
				"tag--corporate-animal-welfare-campaigns"
				"tag--corporate-governance"
				"tag--corruption"
				"tag--cost-benefit-analysis"
				"tag--cost-effectiveness"
				"tag--cost-effectiveness-analysis"
				"tag--counterfactual-reasoning"
				"tag--coworking-spaces"
				"tag--creative-writing-contest"
				"tag--credal-resilience"
				"tag--criminal-justice-reform"
				"tag--criticism-and-red-teaming-contest"
				"tag--criticism-of-effective-altruism"
				"tag--criticism-of-effective-altruism-culture"
				"tag--criticism-of-effective-altruist-causes"
				"tag--criticism-of-effective-altruist-organizations"
				"tag--criticism-of-longtermism-and-existential-risk-studies"
				"tag--crucial-consideration"
				"tag--crustacean-welfare"
				"tag--crux"
				"tag--cryonics"
				"tag--cuban-missile-crisis"
				"tag--cultivated-meat"
				"tag--cultural-evolution"
				"tag--cultural-persistence"
				"tag--data-ea-community-1"
				"tag--data-and-tech-projects"
				"tag--data-science"
				"tag--david-pearce-1"
				"tag--decision-theory"
				"tag--decision-theoretic-uncertainty"
				"tag--deepmind"
				"tag--defense-in-depth"
				"tag--definition-of-effective-altruism"
				"tag--demandingness-of-morality"
				"tag--democracy"
				"tag--deontology"
				"tag--derek-parfit"
				"tag--development-media-international"
				"tag--deworming"
				"tag--dietary-change"
				"tag--differential-progress"
				"tag--digital-person"
				"tag--diminishing-returns"
				"tag--discussion-norms"
				"tag--disentanglement-research"
				"tag--dispensers-for-safe-water"
				"tag--distribution-of-cost-effectiveness"
				"tag--diversity-and-inclusion"
				"tag--divestment"
				"tag--documentaries"
				"tag--doing-good-better"
				"tag--donation-choice"
				"tag--donation-matching"
				"tag--donation-pledge"
				"tag--donation-writeup"
				"tag--donor-lotteries"
				"tag--doomsday-argument"
				"tag--draft-amnesty-day"
				"tag--dual-use"
				"tag--dustin-moskovitz"
				"tag--dylan-matthews"
				"tag--dystopia"
				"tag--ea-giving-tuesday"
				"tag--ea-good-governance-project"
				"tag--ea-librarian-project-inactive"
				"tag--ea-organization-updates-monthly-series"
				"tag--ea-talks-previously-earadio-project"
				"tag--							  eagx"
				"tag--earning-to-give"
				"tag--eastern-europe"
				"tag--economic-growth"
				"tag--economic-inequality"
				"tag--economics"
				"tag--economics-of-artificial-intelligence"
				"tag--education"
				"tag--effective-altruism-anywhere"
				"tag--effective-altruism-behavioral-science-newsletter"
				"tag--effective-altruism-coaching"
				"tag--effective-altruism-consulting-network"
				"tag--effective-altruism-forum-1"
				"tag--effective-altruism-foundation"
				"tag--effective-altruism-funds"
				"tag--effective-altruism-global"
				"tag--effective-altruism-group-organisers-survey"
				"tag--effective-altruism-hub"
				"tag--effective-altruism-infrastructure-fund"
				"tag--effective-altruism-israel"
				"tag--effective-altruism-london"
				"tag--effective-altruism-newsletter"
				"tag--effective-altruism-policy-analytics"
				"tag--effective-altruism-survey"
				"tag--effective-altruism-for-christians"
				"tag--effective-altruism-for-jews"
				"tag--effective-institutions-project"
				"tag--effective-thesis"
				"tag--effective-ventures"
				"tag--effective-altruism-art-and-fiction"
				"tag--effective-altruism-culture"
				"tag--effective-altruism-education"
				"tag--effective-altruism-funding"
				"tag--effective-altruism-groups"
				"tag--effective-altruism-in-french"
				"tag--effective-altruism-in-spanish"
				"tag--effective-altruism-in-the-media"
				"tag--effective-altruism-lifestyle"
				"tag--effective-altruism-messaging"
				"tag--effective-altruism-outreach-in-schools"
				"tag--effective-animal-advocacy"
				"tag--effective-giving"
				"tag--effektiv-spenden-org"
				"tag--electoral-politics"
				"tag--electoral-reform"
				"tag--eliezer-yudkowsky"
				"tag--elon-musk"
				"tag--emergency-response"
				"tag--engineering"
				"tag--entrepreneurship"
				"tag--environmental-science"
				"tag--epistemic-deference"
				"tag--epistemology"
				"tag--epoch"
				"tag--estimate-elicitation-and-crowdsourcing"
				"tag--estimation-of-existential-risk"
				"tag--ethics-of-artificial-intelligence"
				"tag--ethics-of-existential-risk"
				"tag--ethics-of-personal-consumption"
				"tag--european-union"
				"tag--event-strategy"
				"tag--evidence-action"
				"tag--excited-vs-obligatory-altruism"
				"tag--exercises"
				"tag--existential-risk"
				"tag--existential-risk-factor"
				"tag--existential-risk-fiction"
				"tag--existential-security"
				"tag--expected-value"
				"tag--expertise"
				"tag--external-praise-for-effective-altruism"
				"tag--extraterrestrial-intelligence"
				"tag--ftx-foundation"
				"tag--ftx-collapse"
				"tag--ftx-collapse-related-resources"
				"tag--fair-trade"
				"tag--family-empowerment-media"
				"tag--family-planning"
				"tag--fanaticism"
				"tag--farmed-animal-welfare"
				"tag--faunalytics"
				"tag--fellowships-and-internships"
				"tag--fermi-estimate"
				"tag--fermi-paradox"
				"tag--field-building"
				"tag--fiscal-sponsorship"
				"tag--fish-welfare-initiative"
				"tag--fish-welfare"
				"tag--flourishing-futures"
				"tag--food-security"
				"tag--forecasting"
				"tag--forecasting-and-estimation"
				"tag--forecasting-newsletter"
				"tag--foreign-aid"
				"tag--foreign-aid-skepticism"
				"tag--foresight-institute"
				"tag--forethought-foundation"
				"tag--fortify-health"
				"tag--forum-prize"
				"tag--forum-review"
				"tag--founders-pledge"
				"tag--funding-high-impact-for-profits"
				"tag--funding-opportunities"
				"tag--funding-request-open"
				"tag--fundraising"
				"tag--future-fund"
				"tag--future-fund-worldview-prize"
				"tag--future-matters"
				"tag--future-perfect"
				"tag--future-of-humanity-institute"
				"tag--future-of-life-institute"
				"tag--game-theory"
				"tag--gene-drives"
				"tag--generation-pledge"
				"tag--geomagnetic-storms"
				"tag--givedirectly"
				"tag--givewell"
				"tag--givewell-change-our-mind-contest"
				"tag--giving-green"
				"tag--giving-multiplier"
				"tag--giving-pledge"
				"tag--giving-what-we-can"
				"tag--giving-what-we-can-newsletter"
				"tag--giving-and-happiness-1"
				"tag--global-outreach"
				"tag--global-catastrophic-risk-institute"
				"tag--global-health-and-development-fund"
				"tag--global-priorities-institute"
				"tag--global-catastrophic-biological-risk"
				"tag--global-catastrophic-risk"
				"tag--global-governance"
				"tag--global-health-and-development"
				"tag--global-health-and-wellbeing"
				"tag--global-poverty"
				"tag--global-priorities-research"
				"tag--good-food-institute"
				"tag--goodhart-s-law"
				"tag--grabby-aliens"
				"tag--grantmaking"
				"tag--great-filter"
				"tag--great-power-conflict"
				"tag--greater-new-york-city-area"
				"tag--guarding-against-pandemics"
				"tag--guesstimate"
				"tag--h5n1-virus"
				"tag--hackathons"
				"tag--happier-lives-institute"
				"tag--hazards-vulnerabilities-and-exposure"
				"tag--healthier-hens"
				"tag--hear-this-idea"
				"tag--hedonism"
				"tag--high-impact-athletes-organization"
				"tag--high-impact-medicine-group"
				"tag--high-impact-professionals-organization"
				"tag--hilary-greaves"
				"tag--hinge-of-history"
				"tag--hiring"
				"tag--history"
				"tag--history-of-effective-altruism"
				"tag--history-of-existential-risk"
				"tag--history-of-philanthropy"
				"tag--holden-karnofsky"
				"tag--human-compatible"
				"tag--human-challenge-trials"
				"tag--human-extinction"
				"tag--humor-1"
				"tag--idinsight"
				"tag--itn-framework"
				"tag--immigration-reform"
				"tag--impact-assessment"
				"tag--impact-investing-1"
				"tag--impactful-government-careers"
				"tag--impostor-syndrome"
				"tag--improving-institutional-decision-making"
				"tag--independent-impression"
				"tag--independent-research"
				"tag--india"
				"tag--indirect-long-term-effects"
				"tag--infinite-ethics"
				"tag--information-hazard"
				"tag--information-security"
				"tag--insect-welfare"
				"tag--inside-vs-outside-view"
				"tag--instrumental-convergence-thesis"
				"tag--intellectual-property"
				"tag--intelligence-explosion"
				"tag--international-organization"
				"tag--international-relations"
				"tag--international-trade"
				"tag--interpersonal-comparisons-of-wellbeing"
				"tag--intervention-evaluation"
				"tag--intrinsic-vs-instrumental-value"
				"tag--introduction-to-effective-altruism"
				"tag--introductory-fellowship"
				"tag--introspective-hedonism"
				"tag--invertebrate-welfare"
				"tag--investing"
				"tag--iterated-embryo-selection"
				"tag--jeremy-bentham"
				"tag--job-listing-closed"
				"tag--job-listing-open"
				"tag--job-profile"
				"tag--johns-hopkins-center-for-health-security"
				"tag--journalism"
				"tag--julia-galef"
				"tag--kelsey-piper"
				"tag--kidney-donation"
				"tag--lean"
				"tag--land-use-reform"
				"tag--law"
				"tag--lead-exposure-elimination-project"
				"tag--leadership"
				"tag--legal-priorities-project"
				"tag--less-discussed-causes"
				"tag--lesswrong"
				"tag--lesswrong-for-ea"
				"tag--leverage-research"
				"tag--life-sciences"
				"tag--list-of-tools-for-collaborative-truth-seeking"
				"tag--local-priorities-research-1"
				"tag--long-reflection"
				"tag--long-term-future-fund"
				"tag--long-range-forecasting"
				"tag--long-term-future"
				"tag--longtermism"
				"tag--longtermist-entrepreneurship-fellowship"
				"tag--longtermist-institutional-reform"
				"tag--longview-philanthropy"
				"tag--low-and-middle-income-countries"
				"tag--machine-intelligence-research-institute"
				"tag--macroeconomic-policy"
				"tag--macrostrategy"
				"tag--magnify-mentoring"
				"tag--malaria"
				"tag--malaria-consortium"
				"tag--management-and-mentoring"
				"tag--manifold-markets"
				"tag--marketing"
				"tag--markets-for-altruism"
				"tag--measuring-and-comparing-value"
				"tag--meat-eater-problem"
				"tag--mechanism-design"
				"tag--medicine"
				"tag--meditation"
				"tag--megaprojects"
				"tag--meme"
				"tag--mental-health-navigator"
				"tag--mental-health"
				"tag--mercy-for-animals"
				"tag--metaculus"
				"tag--metaethics"
				"tag--metascience"
				"tag--michael-huemer"
				"tag--micronutrient-deficiency"
				"tag--misinformation-1"
				"tag--mission-correlated-investing"
				"tag--model-uncertainty"
				"tag--models"
				"tag--monthly-overload-of-effective-altruism"
				"tag--moral-advocacy"
				"tag--moral-circle-expansion-1"
				"tag--moral-cooperation"
				"tag--moral-offsetting"
				"tag--moral-patienthood"
				"tag--moral-philosophy"
				"tag--moral-psychology"
				"tag--moral-trade"
				"tag--moral-uncertainty"
				"tag--moral-weight"
				"tag--motivational"
				"tag--movement-collapse"
				"tag--naive-vs-sophisticated-consequentialism"
				"tag--natural-existential-risk"
				"tag--near-term-ai-ethics"
				"tag--negative-utilitarianism"
				"tag--neglectedness"
				"tag--network-building"
				"tag--neurotechnology"
				"tag--neutrality"
				"tag--new-harvest"
				"tag--news-relevant-to-effective-altruism"
				"tag--newsletters"
				"tag--nick-bostrom"
				"tag--non-humans-and-the-long-term-future"
				"tag--non-wellbeing-sources-of-value"
				"tag--nonlinear-fund"
				"tag--nonprofit-governance"
				"tag--normative-ethics"
				"tag--north-korea"
				"tag--nuclear-energy"
				"tag--nuclear-security"
				"tag--nuclear-warfare-1"
				"tag--nuclear-winter"
				"tag--obituary"
				"tag--one-for-the-world-1"
				"tag--online-effective-altruism-communities"
				"tag--open-philanthropy"
				"tag--open-thread"
				"tag--openai"
				"tag--operations"
				"tag--operations-research"
				"tag--optimizer-s-curse"
				"tag--organisation-for-the-prevention-of-intense-suffering"
				"tag--organization-strategy"
				"tag--organization-updates"
				"tag--orthogonality-thesis"
				"tag--other-moral-theories"
				"tag--ought"
				"tag--our-world-in-data"
				"tag--pain-and-suffering"
				"tag--pandemic-preparedness"
				"tag--parenting"
				"tag--pascal-s-mugging"
				"tag--patient-altruism"
				"tag--paul-christiano"
				"tag--peace-and-conflict-studies"
				"tag--person-affecting-views"
				"tag--personal-development"
				"tag--personal-finance"
				"tag--personal-fit"
				"tag--personal-identity"
				"tag--peter-singer"
				"tag--petrov-day"
				"tag--philanthropic-coordination"
				"tag--philanthropic-diversification"
				"tag--philip-tetlock"
				"tag--philippines"
				"tag--philosophy"
				"tag--philosophy-of-effective-altruism"
				"tag--philosophy-of-mind"
				"tag--pineapple-operations"
				"tag--podcasts"
				"tag--policy"
				"tag--political-polarization"
				"tag--population-decline"
				"tag--population-ethics"
				"tag--postmortems-and-retrospectives"
				"tag--power-dynamics-in-effective-altruism"
				"tag--practical"
				"tag--prediction-markets"
				"tag--prize"
				"tag--probably-good"
				"tag--product-management"
				"tag--productivity"
				"tag--progress-studies"
				"tag--project-for-awesome"
				"tag--project-voting"
				"tag--proliferation"
				"tag--psychedelics"
				"tag--psychology"
				"tag--psychotherapy"
				"tag--public-giving"
				"tag--public-goods"
				"tag--public-interest-technology"
				"tag--public-relations"
				"tag--publication-norms"
				"tag--qualia-research-institute"
				"tag--quantified-uncertainty-research-institute"
				"tag--quantum-computing"
				"tag--quotes"
				"tag--rc-forward"
				"tag--raising-for-effective-giving"
				"tag--randomized-controlled-trials"
				"tag--rationality"
				"tag--rationality-community"
				"tag--ready-research"
				"tag--reasoning-transparency"
				"tag--red-teaming"
				"tag--redwood-research"
				"tag--refuges"
				"tag--religion"
				"tag--replaceability"
				"tag--repugnant-conclusion"
				"tag--request-for-proposal"
				"tag--requests-closed"
				"tag--requests-open"
				"tag--research"
				"tag--research-agendas-questions-and-project-lists"
				"tag--research-careers"
				"tag--research-methods"
				"tag--research-summary"
				"tag--research-training-programs"
				"tag--resilient-food"
				"tag--resource-tradeoffs"
				"tag--rethink-charity"
				"tag--rethink-priorities"
				"tag--review-crosspost"
				"tag--risk-assessment"
				"tag--risk-aversion"
				"tag--risks-from-malevolent-actors"
				"tag--robin-hanson"
				"tag--role-impact"
				"tag--russia"
				"tag--s-risk"
				"tag--sci-foundation"
				"tag--spc-framework"
				"tag--safeguarding-liberal-democracy"
				"tag--sam-bankman-fried"
				"tag--samotsvety-forecasting"
				"tag--scalably-using-labour"
				"tag--science-and-technology-studies"
				"tag--scientific-progress"
				"tag--scope-neglect"
				"tag--scott-alexander"
				"tag--scout-mindset"
				"tag--self-care"
				"tag--semiconductors"
				"tag--sentience-1"
				"tag--sentience-institute"
				"tag--shrimp-welfare-project"
				"tag--simulation-argument"
				"tag--smallpox-eradication-programme"
				"tag--sogive"
				"tag--social-and-intellectual-movements"
				"tag--social-science-1"
				"tag--socially-responsible-investing"
				"tag--software-engineering"
				"tag--space-colonization"
				"tag--space-governance"
				"tag--spaced-repetition"
				"tag--spark-wave"
				"tag--speciesism"
				"tag--speeding-up-development"
				"tag--spillover-effects"
				"tag--squiggle"
				"tag--standards-and-regulation"
				"tag--stanford-existential-risks-initiative"
				"tag--stanislav-petrov"
				"tag--statistics"
				"tag--status-quo-bias"
				"tag--steven-pinker"
				"tag--strongminds"
				"tag--student-projects"
				"tag--students-for-high-impact-charity"
				"tag--subjective-wellbeing"
				"tag--suffering-focused-ethics"
				"tag--summer-program-on-applied-rationality-and-cognition"
				"tag--superintelligence"
				"tag--superintelligence-book"
				"tag--supervolcano"
				"tag--surveillance"
				"tag--surveys"
				"tag--survival-and-flourishing"
				"tag--suvita"
				"tag--swiss-existential-risk-initiative"
				"tag--systemic-change"
				"tag--tabletop-exercises"
				"tag--take-action"
				"tag--task-y"
				"tag--teaching-materials"
				"tag--technology-race"
				"tag--temporal-discounting"
				"tag--terrorism"
				"tag--the-humane-league"
				"tag--the-life-you-can-save"
				"tag--the-precipice"
				"tag--the-unjournal"
				"tag--theory-of-change"
				"tag--think-tanks"
				"tag--thinking-at-the-margin"
				"tag--time-of-perils"
				"tag--timing-of-philanthropy"
				"tag--tobacco-control"
				"tag--toby-ord"
				"tag--total-view"
				"tag--totalitarianism"
				"tag--tractability"
				"tag--training-for-good"
				"tag--trajectory-change"
				"tag--transformative-artificial-intelligence"
				"tag--transhumanism"
				"tag--translation"
				"tag--transparency"
				"tag--twitter"
				"tag--tyler-cowen"
				"tag--uk-policy"
				"tag--us-policy"
				"tag--ukraine"
				"tag--united-kingdom"
				"tag--united-nations-1"
				"tag--united-states"
				"tag--universal-basic-income"
				"tag--university-groups"
				"tag--utilitarianism"
				"tag--vaccines"
				"tag--valence"
				"tag--value-drift"
				"tag--value-lock-in"
				"tag--value-of-information"
				"tag--value-of-movement-growth"
				"tag--video-1"
				"tag--virtue-ethics"
				"tag--vitalik-buterin"
				"tag--volcanic-winter"
				"tag--volunteering"
				"tag--vulnerable-world-hypothesis"
				"tag--warning-shot"
				"tag--wave"
				"tag--weapons-of-mass-destruction"
				"tag--weekly-summaries-project"
				"tag--welfare-biology"
				"tag--welfare-economics"
				"tag--welfarism"
				"tag--wellbeing"
				"tag--what-we-owe-the-future"
				"tag--whole-brain-emulation"
				"tag--wikis"
				"tag--wild-animal-initiative"
				"tag--wild-animal-welfare"
				"tag--william-macaskill"
				"tag--windfall-clause"
				"tag--women-s-health-and-welfare"
				"tag--working-at-ea-vs-non-ea-orgs"
				"tag--workplace-advocacy"
				"tag--workplace-groups"
				"tag--workshops-retreats-summits"
				"tag--worldview-diversity-in-effective-altruism"
				"tag--writing-advice"))

(defvar tlon-bae-eawiki-urls '("https://forum.effectivealtruism.org/topics/impact"
			       "https://forum.effectivealtruism.org/topics/1day-sooner"
			       "https://forum.effectivealtruism.org/topics/80-000-hours"
			       "https://forum.effectivealtruism.org/topics/80-000-hours-podcast"
			       "https://forum.effectivealtruism.org/topics/ai-alignment-forum"
			       "https://forum.effectivealtruism.org/topics/ai-impacts"
			       "https://forum.effectivealtruism.org/topics/ai-safety-camp"
			       "https://forum.effectivealtruism.org/topics/ai-safety-support"
			       "https://forum.effectivealtruism.org/topics/ai-alignment"
			       "https://forum.effectivealtruism.org/topics/ai-forecasting"
			       "https://forum.effectivealtruism.org/topics/ai-governance"
			       "https://forum.effectivealtruism.org/topics/ai-interpretability"
			       "https://forum.effectivealtruism.org/topics/ai-race"
			       "https://forum.effectivealtruism.org/topics/ai-risk"
			       "https://forum.effectivealtruism.org/topics/ai-safety"
			       "https://forum.effectivealtruism.org/topics/ai-safety-resources-and-materials"
			       "https://forum.effectivealtruism.org/topics/ai-skepticism"
			       "https://forum.effectivealtruism.org/topics/ai-takeoff"
			       "https://forum.effectivealtruism.org/topics/allfed"
			       "https://forum.effectivealtruism.org/topics/abdul-latif-jameel-poverty-action-lab"
			       "https://forum.effectivealtruism.org/topics/academia-1"
			       "https://forum.effectivealtruism.org/topics/accidental-harm"
			       "https://forum.effectivealtruism.org/topics/adjusted-life-year"
			       "https://forum.effectivealtruism.org/topics/against-malaria-foundation"
			       "https://forum.effectivealtruism.org/topics/aging-research"
			       "https://forum.effectivealtruism.org/topics/aid-and-paternalism"
			       "https://forum.effectivealtruism.org/topics/air-pollution"
			       "https://forum.effectivealtruism.org/topics/albert-schweitzer-foundation"
			       "https://forum.effectivealtruism.org/topics/aligned-ai"
			       "https://forum.effectivealtruism.org/topics/alignment-research-center"
			       "https://forum.effectivealtruism.org/topics/alignment-tax"
			       "https://forum.effectivealtruism.org/topics/all-party-parliamentary-group-for-future-generations"
			       "https://forum.effectivealtruism.org/topics/altruistic-coordination"
			       "https://forum.effectivealtruism.org/topics/altruistic-motivation"
			       "https://forum.effectivealtruism.org/topics/altruistic-wager"
			       "https://forum.effectivealtruism.org/topics/ambition"
			       "https://forum.effectivealtruism.org/topics/anders-sandberg"
			       "https://forum.effectivealtruism.org/topics/andreas-mogensen"
			       "https://forum.effectivealtruism.org/topics/anima-international"
			       "https://forum.effectivealtruism.org/topics/animal-advocacy-careers"
			       "https://forum.effectivealtruism.org/topics/animal-ask"
			       "https://forum.effectivealtruism.org/topics/animal-charity-evaluators"
			       "https://forum.effectivealtruism.org/topics/animal-ethics"
			       "https://forum.effectivealtruism.org/topics/animal-welfare-fund"
			       "https://forum.effectivealtruism.org/topics/animal-product-alternatives"
			       "https://forum.effectivealtruism.org/topics/animal-sentience"
			       "https://forum.effectivealtruism.org/topics/animal-welfare"
			       "https://forum.effectivealtruism.org/topics/anthropic"
			       "https://forum.effectivealtruism.org/topics/anthropics"
			       "https://forum.effectivealtruism.org/topics/anthropogenic-existential-risk"
			       "https://forum.effectivealtruism.org/topics/antibiotic-resistance"
			       "https://forum.effectivealtruism.org/topics/antitrust-law"
			       "https://forum.effectivealtruism.org/topics/application-announcements"
			       "https://forum.effectivealtruism.org/topics/applied-ethics"
			       "https://forum.effectivealtruism.org/topics/april-fools-day-1"
			       "https://forum.effectivealtruism.org/topics/arb"
			       "https://forum.effectivealtruism.org/topics/architecture"
			       "https://forum.effectivealtruism.org/topics/armed-conflict"
			       "https://forum.effectivealtruism.org/topics/artificial-intelligence"
			       "https://forum.effectivealtruism.org/topics/artificial-sentience"
			       "https://forum.effectivealtruism.org/topics/asia"
			       "https://forum.effectivealtruism.org/topics/ask-me-anything"
			       "https://forum.effectivealtruism.org/topics/assistants"
			       "https://forum.effectivealtruism.org/topics/asteroids"
			       "https://forum.effectivealtruism.org/topics/astronomical-waste"
			       "https://forum.effectivealtruism.org/topics/asymmetry"
			       "https://forum.effectivealtruism.org/topics/atomically-precise-manufacturing"
			       "https://forum.effectivealtruism.org/topics/audio"
			       "https://forum.effectivealtruism.org/topics/automation"
			       "https://forum.effectivealtruism.org/topics/autonomous-weapon"
			       "https://forum.effectivealtruism.org/topics/axiology"
			       "https://forum.effectivealtruism.org/topics/ballot-initiative"
			       "https://forum.effectivealtruism.org/topics/bayes-theorem"
			       "https://forum.effectivealtruism.org/topics/bayesian-epistemology"
			       "https://forum.effectivealtruism.org/topics/berkeley-existential-risk-initiative"
			       "https://forum.effectivealtruism.org/topics/biodiversity-loss"
			       "https://forum.effectivealtruism.org/topics/bioethics"
			       "https://forum.effectivealtruism.org/topics/biosecurity"
			       "https://forum.effectivealtruism.org/topics/biosecurity-and-pandemics"
			       "https://forum.effectivealtruism.org/topics/biosurveillance"
			       "https://forum.effectivealtruism.org/topics/biotechnology"
			       "https://forum.effectivealtruism.org/topics/bitcoin"
			       "https://forum.effectivealtruism.org/topics/blockchain-technology"
			       "https://forum.effectivealtruism.org/topics/blogging"
			       "https://forum.effectivealtruism.org/topics/books"
			       "https://forum.effectivealtruism.org/topics/bostrom-apology"
			       "https://forum.effectivealtruism.org/topics/bounty-closed"
			       "https://forum.effectivealtruism.org/topics/bounty-open"
			       "https://forum.effectivealtruism.org/topics/brain-computer-interfaces"
			       "https://forum.effectivealtruism.org/topics/brian-tomasik"
			       "https://forum.effectivealtruism.org/topics/broad-vs-narrow-interventions"
			       "https://forum.effectivealtruism.org/topics/bryan-caplan"
			       "https://forum.effectivealtruism.org/topics/building-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/building-the-field-of-ai-safety"
			       "https://forum.effectivealtruism.org/topics/burden-of-disease"
			       "https://forum.effectivealtruism.org/topics/covid-19-pandemic"
			       "https://forum.effectivealtruism.org/topics/california-effect"
			       "https://forum.effectivealtruism.org/topics/cambridge-existential-risks-initiative"
			       "https://forum.effectivealtruism.org/topics/career-advising"
			       "https://forum.effectivealtruism.org/topics/career-capital"
			       "https://forum.effectivealtruism.org/topics/career-choice"
			       "https://forum.effectivealtruism.org/topics/career-framework"
			       "https://forum.effectivealtruism.org/topics/carl-shulman"
			       "https://forum.effectivealtruism.org/topics/carrick-flynn"
			       "https://forum.effectivealtruism.org/topics/cash-transfers"
			       "https://forum.effectivealtruism.org/topics/cause-exploration-prizes"
			       "https://forum.effectivealtruism.org/topics/cause-innovation-bootcamp"
			       "https://forum.effectivealtruism.org/topics/cause-x"
			       "https://forum.effectivealtruism.org/topics/cause-candidates"
			       "https://forum.effectivealtruism.org/topics/cause-neutrality"
			       "https://forum.effectivealtruism.org/topics/cause-prioritization"
			       "https://forum.effectivealtruism.org/topics/center-for-applied-rationality"
			       "https://forum.effectivealtruism.org/topics/center-for-election-science"
			       "https://forum.effectivealtruism.org/topics/center-for-human-compatible-artificial-intelligence"
			       "https://forum.effectivealtruism.org/topics/center-for-reducing-suffering"
			       "https://forum.effectivealtruism.org/topics/center-on-long-term-risk"
			       "https://forum.effectivealtruism.org/topics/centre-for-effective-altruism-1"
			       "https://forum.effectivealtruism.org/topics/centre-for-enabling-ea-learning-and-research"
			       "https://forum.effectivealtruism.org/topics/centre-for-long-term-resilience"
			       "https://forum.effectivealtruism.org/topics/centre-for-the-governance-of-ai"
			       "https://forum.effectivealtruism.org/topics/centre-for-the-study-of-existential-risk"
			       "https://forum.effectivealtruism.org/topics/certificate-of-impact"
			       "https://forum.effectivealtruism.org/topics/charity-entrepreneurship"
			       "https://forum.effectivealtruism.org/topics/charity-science-foundation"
			       "https://forum.effectivealtruism.org/topics/charity-evaluation"
			       "https://forum.effectivealtruism.org/topics/charity-incubation"
			       "https://forum.effectivealtruism.org/topics/charter-cities"
			       "https://forum.effectivealtruism.org/topics/chatgpt"
			       "https://forum.effectivealtruism.org/topics/china"
			       "https://forum.effectivealtruism.org/topics/civilizational-collapse"
			       "https://forum.effectivealtruism.org/topics/classic-repost"
			       "https://forum.effectivealtruism.org/topics/classical-utilitarianism"
			       "https://forum.effectivealtruism.org/topics/climate-change"
			       "https://forum.effectivealtruism.org/topics/climate-engineering"
			       "https://forum.effectivealtruism.org/topics/cluelessness"
			       "https://forum.effectivealtruism.org/topics/cluster-headache"
			       "https://forum.effectivealtruism.org/topics/coaching"
			       "https://forum.effectivealtruism.org/topics/cognitive-bias"
			       "https://forum.effectivealtruism.org/topics/cognitive-decline"
			       "https://forum.effectivealtruism.org/topics/cognitive-enhancement"
			       "https://forum.effectivealtruism.org/topics/collections-and-resources"
			       "https://forum.effectivealtruism.org/topics/college-advice"
			       "https://forum.effectivealtruism.org/topics/communities-adjacent-to-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/community"
			       "https://forum.effectivealtruism.org/topics/community-builder-writing-contest"
			       "https://forum.effectivealtruism.org/topics/community-epistemic-health"
			       "https://forum.effectivealtruism.org/topics/community-experiences"
			       "https://forum.effectivealtruism.org/topics/community-housing"
			       "https://forum.effectivealtruism.org/topics/community-infrastructure"
			       "https://forum.effectivealtruism.org/topics/community-projects"
			       "https://forum.effectivealtruism.org/topics/compassion-in-world-farming"
			       "https://forum.effectivealtruism.org/topics/competitive-debating"
			       "https://forum.effectivealtruism.org/topics/computational-power-of-the-human-brain"
			       "https://forum.effectivealtruism.org/topics/compute-governance"
			       "https://forum.effectivealtruism.org/topics/conferences"
			       "https://forum.effectivealtruism.org/topics/conflicts-of-interest"
			       "https://forum.effectivealtruism.org/topics/conjecture"
			       "https://forum.effectivealtruism.org/topics/conjunctive-vs-disjunctive-risk-models"
			       "https://forum.effectivealtruism.org/topics/consciousness-research"
			       "https://forum.effectivealtruism.org/topics/consequences-of-ai-timelines"
			       "https://forum.effectivealtruism.org/topics/consequentialism"
			       "https://forum.effectivealtruism.org/topics/conservation"
			       "https://forum.effectivealtruism.org/topics/constraints-on-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/consultancy"
			       "https://forum.effectivealtruism.org/topics/cooperative-ai-1"
			       "https://forum.effectivealtruism.org/topics/corporate-animal-welfare-campaigns"
			       "https://forum.effectivealtruism.org/topics/corporate-governance"
			       "https://forum.effectivealtruism.org/topics/corruption"
			       "https://forum.effectivealtruism.org/topics/cost-benefit-analysis"
			       "https://forum.effectivealtruism.org/topics/cost-effectiveness"
			       "https://forum.effectivealtruism.org/topics/cost-effectiveness-analysis"
			       "https://forum.effectivealtruism.org/topics/counterfactual-reasoning"
			       "https://forum.effectivealtruism.org/topics/coworking-spaces"
			       "https://forum.effectivealtruism.org/topics/creative-writing-contest"
			       "https://forum.effectivealtruism.org/topics/credal-resilience"
			       "https://forum.effectivealtruism.org/topics/criminal-justice-reform"
			       "https://forum.effectivealtruism.org/topics/criticism-and-red-teaming-contest"
			       "https://forum.effectivealtruism.org/topics/criticism-of-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/criticism-of-effective-altruism-culture"
			       "https://forum.effectivealtruism.org/topics/criticism-of-effective-altruist-causes"
			       "https://forum.effectivealtruism.org/topics/criticism-of-effective-altruist-organizations"
			       "https://forum.effectivealtruism.org/topics/criticism-of-longtermism-and-existential-risk-studies"
			       "https://forum.effectivealtruism.org/topics/crucial-consideration"
			       "https://forum.effectivealtruism.org/topics/crustacean-welfare"
			       "https://forum.effectivealtruism.org/topics/crux"
			       "https://forum.effectivealtruism.org/topics/cryonics"
			       "https://forum.effectivealtruism.org/topics/cuban-missile-crisis"
			       "https://forum.effectivealtruism.org/topics/cultivated-meat"
			       "https://forum.effectivealtruism.org/topics/cultural-evolution"
			       "https://forum.effectivealtruism.org/topics/cultural-persistence"
			       "https://forum.effectivealtruism.org/topics/data-ea-community-1"
			       "https://forum.effectivealtruism.org/topics/data-and-tech-projects"
			       "https://forum.effectivealtruism.org/topics/data-science"
			       "https://forum.effectivealtruism.org/topics/david-pearce-1"
			       "https://forum.effectivealtruism.org/topics/decision-theory"
			       "https://forum.effectivealtruism.org/topics/decision-theoretic-uncertainty"
			       "https://forum.effectivealtruism.org/topics/deepmind"
			       "https://forum.effectivealtruism.org/topics/defense-in-depth"
			       "https://forum.effectivealtruism.org/topics/definition-of-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/demandingness-of-morality"
			       "https://forum.effectivealtruism.org/topics/democracy"
			       "https://forum.effectivealtruism.org/topics/deontology"
			       "https://forum.effectivealtruism.org/topics/derek-parfit"
			       "https://forum.effectivealtruism.org/topics/development-media-international"
			       "https://forum.effectivealtruism.org/topics/deworming"
			       "https://forum.effectivealtruism.org/topics/dietary-change"
			       "https://forum.effectivealtruism.org/topics/differential-progress"
			       "https://forum.effectivealtruism.org/topics/digital-person"
			       "https://forum.effectivealtruism.org/topics/diminishing-returns"
			       "https://forum.effectivealtruism.org/topics/discussion-norms"
			       "https://forum.effectivealtruism.org/topics/disentanglement-research"
			       "https://forum.effectivealtruism.org/topics/dispensers-for-safe-water"
			       "https://forum.effectivealtruism.org/topics/distribution-of-cost-effectiveness"
			       "https://forum.effectivealtruism.org/topics/diversity-and-inclusion"
			       "https://forum.effectivealtruism.org/topics/divestment"
			       "https://forum.effectivealtruism.org/topics/documentaries"
			       "https://forum.effectivealtruism.org/topics/doing-good-better"
			       "https://forum.effectivealtruism.org/topics/donation-choice"
			       "https://forum.effectivealtruism.org/topics/donation-matching"
			       "https://forum.effectivealtruism.org/topics/donation-pledge"
			       "https://forum.effectivealtruism.org/topics/donation-writeup"
			       "https://forum.effectivealtruism.org/topics/donor-lotteries"
			       "https://forum.effectivealtruism.org/topics/doomsday-argument"
			       "https://forum.effectivealtruism.org/topics/draft-amnesty-day"
			       "https://forum.effectivealtruism.org/topics/dual-use"
			       "https://forum.effectivealtruism.org/topics/dustin-moskovitz"
			       "https://forum.effectivealtruism.org/topics/dylan-matthews"
			       "https://forum.effectivealtruism.org/topics/dystopia"
			       "https://forum.effectivealtruism.org/topics/ea-giving-tuesday"
			       "https://forum.effectivealtruism.org/topics/ea-good-governance-project"
			       "https://forum.effectivealtruism.org/topics/ea-librarian-project-inactive"
			       "https://forum.effectivealtruism.org/topics/ea-organization-updates-monthly-series"
			       "https://forum.effectivealtruism.org/topics/ea-talks-previously-earadio-project"
			       "https://forum.effectivealtruism.org/topics/eagx"
			       "https://forum.effectivealtruism.org/topics/earning-to-give"
			       "https://forum.effectivealtruism.org/topics/eastern-europe"
			       "https://forum.effectivealtruism.org/topics/economic-growth"
			       "https://forum.effectivealtruism.org/topics/economic-inequality"
			       "https://forum.effectivealtruism.org/topics/economics"
			       "https://forum.effectivealtruism.org/topics/economics-of-artificial-intelligence"
			       "https://forum.effectivealtruism.org/topics/education"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-anywhere"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-behavioral-science-newsletter"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-coaching"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-consulting-network"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-forum-1"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-foundation"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-funds"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-global"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-group-organisers-survey"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-hub"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-infrastructure-fund"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-israel"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-london"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-newsletter"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-policy-analytics"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-survey"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-for-christians"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-for-jews"
			       "https://forum.effectivealtruism.org/topics/effective-institutions-project"
			       "https://forum.effectivealtruism.org/topics/effective-thesis"
			       "https://forum.effectivealtruism.org/topics/effective-ventures"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-art-and-fiction"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-culture"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-education"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-funding"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-groups"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-in-french"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-in-spanish"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-in-the-media"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-lifestyle"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-messaging"
			       "https://forum.effectivealtruism.org/topics/effective-altruism-outreach-in-schools"
			       "https://forum.effectivealtruism.org/topics/effective-animal-advocacy"
			       "https://forum.effectivealtruism.org/topics/effective-giving"
			       "https://forum.effectivealtruism.org/topics/effektiv-spenden-org"
			       "https://forum.effectivealtruism.org/topics/electoral-politics"
			       "https://forum.effectivealtruism.org/topics/electoral-reform"
			       "https://forum.effectivealtruism.org/topics/eliezer-yudkowsky"
			       "https://forum.effectivealtruism.org/topics/elon-musk"
			       "https://forum.effectivealtruism.org/topics/emergency-response"
			       "https://forum.effectivealtruism.org/topics/engineering"
			       "https://forum.effectivealtruism.org/topics/entrepreneurship"
			       "https://forum.effectivealtruism.org/topics/environmental-science"
			       "https://forum.effectivealtruism.org/topics/epistemic-deference"
			       "https://forum.effectivealtruism.org/topics/epistemology"
			       "https://forum.effectivealtruism.org/topics/epoch"
			       "https://forum.effectivealtruism.org/topics/estimate-elicitation-and-crowdsourcing"
			       "https://forum.effectivealtruism.org/topics/estimation-of-existential-risk"
			       "https://forum.effectivealtruism.org/topics/ethics-of-artificial-intelligence"
			       "https://forum.effectivealtruism.org/topics/ethics-of-existential-risk"
			       "https://forum.effectivealtruism.org/topics/ethics-of-personal-consumption"
			       "https://forum.effectivealtruism.org/topics/european-union"
			       "https://forum.effectivealtruism.org/topics/event-strategy"
			       "https://forum.effectivealtruism.org/topics/evidence-action"
			       "https://forum.effectivealtruism.org/topics/excited-vs-obligatory-altruism"
			       "https://forum.effectivealtruism.org/topics/exercises"
			       "https://forum.effectivealtruism.org/topics/existential-risk"
			       "https://forum.effectivealtruism.org/topics/existential-risk-factor"
			       "https://forum.effectivealtruism.org/topics/existential-risk-fiction"
			       "https://forum.effectivealtruism.org/topics/existential-security"
			       "https://forum.effectivealtruism.org/topics/expected-value"
			       "https://forum.effectivealtruism.org/topics/expertise"
			       "https://forum.effectivealtruism.org/topics/external-praise-for-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/extraterrestrial-intelligence"
			       "https://forum.effectivealtruism.org/topics/ftx-foundation"
			       "https://forum.effectivealtruism.org/topics/ftx-collapse"
			       "https://forum.effectivealtruism.org/topics/ftx-collapse-related-resources"
			       "https://forum.effectivealtruism.org/topics/fair-trade"
			       "https://forum.effectivealtruism.org/topics/family-empowerment-media"
			       "https://forum.effectivealtruism.org/topics/family-planning"
			       "https://forum.effectivealtruism.org/topics/fanaticism"
			       "https://forum.effectivealtruism.org/topics/farmed-animal-welfare"
			       "https://forum.effectivealtruism.org/topics/faunalytics"
			       "https://forum.effectivealtruism.org/topics/fellowships-and-internships"
			       "https://forum.effectivealtruism.org/topics/fermi-estimate"
			       "https://forum.effectivealtruism.org/topics/fermi-paradox"
			       "https://forum.effectivealtruism.org/topics/field-building"
			       "https://forum.effectivealtruism.org/topics/fiscal-sponsorship"
			       "https://forum.effectivealtruism.org/topics/fish-welfare-initiative"
			       "https://forum.effectivealtruism.org/topics/fish-welfare"
			       "https://forum.effectivealtruism.org/topics/flourishing-futures"
			       "https://forum.effectivealtruism.org/topics/food-security"
			       "https://forum.effectivealtruism.org/topics/forecasting"
			       "https://forum.effectivealtruism.org/topics/forecasting-and-estimation"
			       "https://forum.effectivealtruism.org/topics/forecasting-newsletter"
			       "https://forum.effectivealtruism.org/topics/foreign-aid"
			       "https://forum.effectivealtruism.org/topics/foreign-aid-skepticism"
			       "https://forum.effectivealtruism.org/topics/foresight-institute"
			       "https://forum.effectivealtruism.org/topics/forethought-foundation"
			       "https://forum.effectivealtruism.org/topics/fortify-health"
			       "https://forum.effectivealtruism.org/topics/forum-prize"
			       "https://forum.effectivealtruism.org/topics/forum-review"
			       "https://forum.effectivealtruism.org/topics/founders-pledge"
			       "https://forum.effectivealtruism.org/topics/funding-high-impact-for-profits"
			       "https://forum.effectivealtruism.org/topics/funding-opportunities"
			       "https://forum.effectivealtruism.org/topics/funding-request-open"
			       "https://forum.effectivealtruism.org/topics/fundraising"
			       "https://forum.effectivealtruism.org/topics/future-fund"
			       "https://forum.effectivealtruism.org/topics/future-fund-worldview-prize"
			       "https://forum.effectivealtruism.org/topics/future-matters"
			       "https://forum.effectivealtruism.org/topics/future-perfect"
			       "https://forum.effectivealtruism.org/topics/future-of-humanity-institute"
			       "https://forum.effectivealtruism.org/topics/future-of-life-institute"
			       "https://forum.effectivealtruism.org/topics/game-theory"
			       "https://forum.effectivealtruism.org/topics/gene-drives"
			       "https://forum.effectivealtruism.org/topics/generation-pledge"
			       "https://forum.effectivealtruism.org/topics/geomagnetic-storms"
			       "https://forum.effectivealtruism.org/topics/givedirectly"
			       "https://forum.effectivealtruism.org/topics/givewell"
			       "https://forum.effectivealtruism.org/topics/givewell-change-our-mind-contest"
			       "https://forum.effectivealtruism.org/topics/giving-green"
			       "https://forum.effectivealtruism.org/topics/giving-multiplier"
			       "https://forum.effectivealtruism.org/topics/giving-pledge"
			       "https://forum.effectivealtruism.org/topics/giving-what-we-can"
			       "https://forum.effectivealtruism.org/topics/giving-what-we-can-newsletter"
			       "https://forum.effectivealtruism.org/topics/giving-and-happiness-1"
			       "https://forum.effectivealtruism.org/topics/global-outreach"
			       "https://forum.effectivealtruism.org/topics/global-catastrophic-risk-institute"
			       "https://forum.effectivealtruism.org/topics/global-health-and-development-fund"
			       "https://forum.effectivealtruism.org/topics/global-priorities-institute"
			       "https://forum.effectivealtruism.org/topics/global-catastrophic-biological-risk"
			       "https://forum.effectivealtruism.org/topics/global-catastrophic-risk"
			       "https://forum.effectivealtruism.org/topics/global-governance"
			       "https://forum.effectivealtruism.org/topics/global-health-and-development"
			       "https://forum.effectivealtruism.org/topics/global-health-and-wellbeing"
			       "https://forum.effectivealtruism.org/topics/global-poverty"
			       "https://forum.effectivealtruism.org/topics/global-priorities-research"
			       "https://forum.effectivealtruism.org/topics/good-food-institute"
			       "https://forum.effectivealtruism.org/topics/goodhart-s-law"
			       "https://forum.effectivealtruism.org/topics/grabby-aliens"
			       "https://forum.effectivealtruism.org/topics/grantmaking"
			       "https://forum.effectivealtruism.org/topics/great-filter"
			       "https://forum.effectivealtruism.org/topics/great-power-conflict"
			       "https://forum.effectivealtruism.org/topics/greater-new-york-city-area"
			       "https://forum.effectivealtruism.org/topics/guarding-against-pandemics"
			       "https://forum.effectivealtruism.org/topics/guesstimate"
			       "https://forum.effectivealtruism.org/topics/hackathons"
			       "https://forum.effectivealtruism.org/topics/happier-lives-institute"
			       "https://forum.effectivealtruism.org/topics/hazards-vulnerabilities-and-exposure"
			       "https://forum.effectivealtruism.org/topics/healthier-hens"
			       "https://forum.effectivealtruism.org/topics/hear-this-idea"
			       "https://forum.effectivealtruism.org/topics/hedonism"
			       "https://forum.effectivealtruism.org/topics/high-impact-athletes-organization"
			       "https://forum.effectivealtruism.org/topics/high-impact-medicine-group"
			       "https://forum.effectivealtruism.org/topics/high-impact-professionals-organization"
			       "https://forum.effectivealtruism.org/topics/hilary-greaves"
			       "https://forum.effectivealtruism.org/topics/hinge-of-history"
			       "https://forum.effectivealtruism.org/topics/hiring"
			       "https://forum.effectivealtruism.org/topics/history"
			       "https://forum.effectivealtruism.org/topics/history-of-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/history-of-existential-risk"
			       "https://forum.effectivealtruism.org/topics/history-of-philanthropy"
			       "https://forum.effectivealtruism.org/topics/holden-karnofsky"
			       "https://forum.effectivealtruism.org/topics/human-compatible"
			       "https://forum.effectivealtruism.org/topics/human-challenge-trials"
			       "https://forum.effectivealtruism.org/topics/human-extinction"
			       "https://forum.effectivealtruism.org/topics/humor-1"
			       "https://forum.effectivealtruism.org/topics/idinsight"
			       "https://forum.effectivealtruism.org/topics/itn-framework"
			       "https://forum.effectivealtruism.org/topics/immigration-reform"
			       "https://forum.effectivealtruism.org/topics/impact-assessment"
			       "https://forum.effectivealtruism.org/topics/impact-investing-1"
			       "https://forum.effectivealtruism.org/topics/impactful-government-careers"
			       "https://forum.effectivealtruism.org/topics/impostor-syndrome"
			       "https://forum.effectivealtruism.org/topics/improving-institutional-decision-making"
			       "https://forum.effectivealtruism.org/topics/independent-impression"
			       "https://forum.effectivealtruism.org/topics/independent-research"
			       "https://forum.effectivealtruism.org/topics/india"
			       "https://forum.effectivealtruism.org/topics/indirect-long-term-effects"
			       "https://forum.effectivealtruism.org/topics/infinite-ethics"
			       "https://forum.effectivealtruism.org/topics/information-hazard"
			       "https://forum.effectivealtruism.org/topics/information-security"
			       "https://forum.effectivealtruism.org/topics/insect-welfare"
			       "https://forum.effectivealtruism.org/topics/inside-vs-outside-view"
			       "https://forum.effectivealtruism.org/topics/instrumental-convergence-thesis"
			       "https://forum.effectivealtruism.org/topics/intellectual-property"
			       "https://forum.effectivealtruism.org/topics/intelligence-explosion"
			       "https://forum.effectivealtruism.org/topics/international-organization"
			       "https://forum.effectivealtruism.org/topics/international-relations"
			       "https://forum.effectivealtruism.org/topics/international-trade"
			       "https://forum.effectivealtruism.org/topics/interpersonal-comparisons-of-wellbeing"
			       "https://forum.effectivealtruism.org/topics/intervention-evaluation"
			       "https://forum.effectivealtruism.org/topics/intrinsic-vs-instrumental-value"
			       "https://forum.effectivealtruism.org/topics/introduction-to-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/introductory-fellowship"
			       "https://forum.effectivealtruism.org/topics/introspective-hedonism"
			       "https://forum.effectivealtruism.org/topics/invertebrate-welfare"
			       "https://forum.effectivealtruism.org/topics/investing"
			       "https://forum.effectivealtruism.org/topics/iterated-embryo-selection"
			       "https://forum.effectivealtruism.org/topics/jeremy-bentham"
			       "https://forum.effectivealtruism.org/topics/job-listing-closed"
			       "https://forum.effectivealtruism.org/topics/job-listing-open"
			       "https://forum.effectivealtruism.org/topics/job-profile"
			       "https://forum.effectivealtruism.org/topics/johns-hopkins-center-for-health-security"
			       "https://forum.effectivealtruism.org/topics/journalism"
			       "https://forum.effectivealtruism.org/topics/julia-galef"
			       "https://forum.effectivealtruism.org/topics/kelsey-piper"
			       "https://forum.effectivealtruism.org/topics/kidney-donation"
			       "https://forum.effectivealtruism.org/topics/lean"
			       "https://forum.effectivealtruism.org/topics/land-use-reform"
			       "https://forum.effectivealtruism.org/topics/law"
			       "https://forum.effectivealtruism.org/topics/lead-exposure-elimination-project"
			       "https://forum.effectivealtruism.org/topics/leadership"
			       "https://forum.effectivealtruism.org/topics/legal-priorities-project"
			       "https://forum.effectivealtruism.org/topics/less-discussed-causes"
			       "https://forum.effectivealtruism.org/topics/lesswrong"
			       "https://forum.effectivealtruism.org/topics/lesswrong-for-ea"
			       "https://forum.effectivealtruism.org/topics/leverage-research"
			       "https://forum.effectivealtruism.org/topics/life-sciences"
			       "https://forum.effectivealtruism.org/topics/list-of-tools-for-collaborative-truth-seeking"
			       "https://forum.effectivealtruism.org/topics/local-priorities-research-1"
			       "https://forum.effectivealtruism.org/topics/long-reflection"
			       "https://forum.effectivealtruism.org/topics/long-term-future-fund"
			       "https://forum.effectivealtruism.org/topics/long-range-forecasting"
			       "https://forum.effectivealtruism.org/topics/long-term-future"
			       "https://forum.effectivealtruism.org/topics/longtermism"
			       "https://forum.effectivealtruism.org/topics/longtermist-entrepreneurship-fellowship"
			       "https://forum.effectivealtruism.org/topics/longtermist-institutional-reform"
			       "https://forum.effectivealtruism.org/topics/longview-philanthropy"
			       "https://forum.effectivealtruism.org/topics/low-and-middle-income-countries"
			       "https://forum.effectivealtruism.org/topics/machine-intelligence-research-institute"
			       "https://forum.effectivealtruism.org/topics/macroeconomic-policy"
			       "https://forum.effectivealtruism.org/topics/macrostrategy"
			       "https://forum.effectivealtruism.org/topics/magnify-mentoring"
			       "https://forum.effectivealtruism.org/topics/malaria"
			       "https://forum.effectivealtruism.org/topics/malaria-consortium"
			       "https://forum.effectivealtruism.org/topics/management-and-mentoring"
			       "https://forum.effectivealtruism.org/topics/manifold-markets"
			       "https://forum.effectivealtruism.org/topics/marketing"
			       "https://forum.effectivealtruism.org/topics/markets-for-altruism"
			       "https://forum.effectivealtruism.org/topics/measuring-and-comparing-value"
			       "https://forum.effectivealtruism.org/topics/meat-eater-problem"
			       "https://forum.effectivealtruism.org/topics/mechanism-design"
			       "https://forum.effectivealtruism.org/topics/medicine"
			       "https://forum.effectivealtruism.org/topics/meditation"
			       "https://forum.effectivealtruism.org/topics/megaprojects"
			       "https://forum.effectivealtruism.org/topics/meme"
			       "https://forum.effectivealtruism.org/topics/mental-health-navigator"
			       "https://forum.effectivealtruism.org/topics/mental-health"
			       "https://forum.effectivealtruism.org/topics/mercy-for-animals"
			       "https://forum.effectivealtruism.org/topics/metaculus"
			       "https://forum.effectivealtruism.org/topics/metaethics"
			       "https://forum.effectivealtruism.org/topics/metascience"
			       "https://forum.effectivealtruism.org/topics/michael-huemer"
			       "https://forum.effectivealtruism.org/topics/micronutrient-deficiency"
			       "https://forum.effectivealtruism.org/topics/misinformation-1"
			       "https://forum.effectivealtruism.org/topics/mission-correlated-investing"
			       "https://forum.effectivealtruism.org/topics/model-uncertainty"
			       "https://forum.effectivealtruism.org/topics/models"
			       "https://forum.effectivealtruism.org/topics/monthly-overload-of-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/moral-advocacy"
			       "https://forum.effectivealtruism.org/topics/moral-circle-expansion-1"
			       "https://forum.effectivealtruism.org/topics/moral-cooperation"
			       "https://forum.effectivealtruism.org/topics/moral-offsetting"
			       "https://forum.effectivealtruism.org/topics/moral-patienthood"
			       "https://forum.effectivealtruism.org/topics/moral-philosophy"
			       "https://forum.effectivealtruism.org/topics/moral-psychology"
			       "https://forum.effectivealtruism.org/topics/moral-trade"
			       "https://forum.effectivealtruism.org/topics/moral-uncertainty"
			       "https://forum.effectivealtruism.org/topics/moral-weight"
			       "https://forum.effectivealtruism.org/topics/motivational"
			       "https://forum.effectivealtruism.org/topics/movement-collapse"
			       "https://forum.effectivealtruism.org/topics/naive-vs-sophisticated-consequentialism"
			       "https://forum.effectivealtruism.org/topics/natural-existential-risk"
			       "https://forum.effectivealtruism.org/topics/near-term-ai-ethics"
			       "https://forum.effectivealtruism.org/topics/negative-utilitarianism"
			       "https://forum.effectivealtruism.org/topics/neglectedness"
			       "https://forum.effectivealtruism.org/topics/network-building"
			       "https://forum.effectivealtruism.org/topics/neurotechnology"
			       "https://forum.effectivealtruism.org/topics/neutrality"
			       "https://forum.effectivealtruism.org/topics/new-harvest"
			       "https://forum.effectivealtruism.org/topics/news-relevant-to-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/newsletters"
			       "https://forum.effectivealtruism.org/topics/nick-bostrom"
			       "https://forum.effectivealtruism.org/topics/non-humans-and-the-long-term-future"
			       "https://forum.effectivealtruism.org/topics/non-wellbeing-sources-of-value"
			       "https://forum.effectivealtruism.org/topics/nonlinear-fund"
			       "https://forum.effectivealtruism.org/topics/nonprofit-governance"
			       "https://forum.effectivealtruism.org/topics/normative-ethics"
			       "https://forum.effectivealtruism.org/topics/north-korea"
			       "https://forum.effectivealtruism.org/topics/nuclear-energy"
			       "https://forum.effectivealtruism.org/topics/nuclear-security"
			       "https://forum.effectivealtruism.org/topics/nuclear-warfare-1"
			       "https://forum.effectivealtruism.org/topics/nuclear-winter"
			       "https://forum.effectivealtruism.org/topics/obituary"
			       "https://forum.effectivealtruism.org/topics/one-for-the-world-1"
			       "https://forum.effectivealtruism.org/topics/online-effective-altruism-communities"
			       "https://forum.effectivealtruism.org/topics/open-philanthropy"
			       "https://forum.effectivealtruism.org/topics/open-thread"
			       "https://forum.effectivealtruism.org/topics/openai"
			       "https://forum.effectivealtruism.org/topics/operations"
			       "https://forum.effectivealtruism.org/topics/operations-research"
			       "https://forum.effectivealtruism.org/topics/optimizer-s-curse"
			       "https://forum.effectivealtruism.org/topics/organisation-for-the-prevention-of-intense-suffering"
			       "https://forum.effectivealtruism.org/topics/organization-strategy"
			       "https://forum.effectivealtruism.org/topics/organization-updates"
			       "https://forum.effectivealtruism.org/topics/orthogonality-thesis"
			       "https://forum.effectivealtruism.org/topics/other-moral-theories"
			       "https://forum.effectivealtruism.org/topics/ought"
			       "https://forum.effectivealtruism.org/topics/our-world-in-data"
			       "https://forum.effectivealtruism.org/topics/pain-and-suffering"
			       "https://forum.effectivealtruism.org/topics/pandemic-preparedness"
			       "https://forum.effectivealtruism.org/topics/parenting"
			       "https://forum.effectivealtruism.org/topics/pascal-s-mugging"
			       "https://forum.effectivealtruism.org/topics/patient-altruism"
			       "https://forum.effectivealtruism.org/topics/paul-christiano"
			       "https://forum.effectivealtruism.org/topics/peace-and-conflict-studies"
			       "https://forum.effectivealtruism.org/topics/person-affecting-views"
			       "https://forum.effectivealtruism.org/topics/personal-development"
			       "https://forum.effectivealtruism.org/topics/personal-finance"
			       "https://forum.effectivealtruism.org/topics/personal-fit"
			       "https://forum.effectivealtruism.org/topics/personal-identity"
			       "https://forum.effectivealtruism.org/topics/peter-singer"
			       "https://forum.effectivealtruism.org/topics/petrov-day"
			       "https://forum.effectivealtruism.org/topics/philanthropic-coordination"
			       "https://forum.effectivealtruism.org/topics/philanthropic-diversification"
			       "https://forum.effectivealtruism.org/topics/philip-tetlock"
			       "https://forum.effectivealtruism.org/topics/philippines"
			       "https://forum.effectivealtruism.org/topics/philosophy"
			       "https://forum.effectivealtruism.org/topics/philosophy-of-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/philosophy-of-mind"
			       "https://forum.effectivealtruism.org/topics/pineapple-operations"
			       "https://forum.effectivealtruism.org/topics/podcasts"
			       "https://forum.effectivealtruism.org/topics/policy"
			       "https://forum.effectivealtruism.org/topics/political-polarization"
			       "https://forum.effectivealtruism.org/topics/population-decline"
			       "https://forum.effectivealtruism.org/topics/population-ethics"
			       "https://forum.effectivealtruism.org/topics/postmortems-and-retrospectives"
			       "https://forum.effectivealtruism.org/topics/power-dynamics-in-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/practical"
			       "https://forum.effectivealtruism.org/topics/prediction-markets"
			       "https://forum.effectivealtruism.org/topics/prize"
			       "https://forum.effectivealtruism.org/topics/probably-good"
			       "https://forum.effectivealtruism.org/topics/product-management"
			       "https://forum.effectivealtruism.org/topics/productivity"
			       "https://forum.effectivealtruism.org/topics/progress-studies"
			       "https://forum.effectivealtruism.org/topics/project-for-awesome"
			       "https://forum.effectivealtruism.org/topics/project-voting"
			       "https://forum.effectivealtruism.org/topics/proliferation"
			       "https://forum.effectivealtruism.org/topics/psychedelics"
			       "https://forum.effectivealtruism.org/topics/psychology"
			       "https://forum.effectivealtruism.org/topics/psychotherapy"
			       "https://forum.effectivealtruism.org/topics/public-giving"
			       "https://forum.effectivealtruism.org/topics/public-goods"
			       "https://forum.effectivealtruism.org/topics/public-interest-technology"
			       "https://forum.effectivealtruism.org/topics/public-relations"
			       "https://forum.effectivealtruism.org/topics/publication-norms"
			       "https://forum.effectivealtruism.org/topics/qualia-research-institute"
			       "https://forum.effectivealtruism.org/topics/quantified-uncertainty-research-institute"
			       "https://forum.effectivealtruism.org/topics/quantum-computing"
			       "https://forum.effectivealtruism.org/topics/quotes"
			       "https://forum.effectivealtruism.org/topics/rc-forward"
			       "https://forum.effectivealtruism.org/topics/raising-for-effective-giving"
			       "https://forum.effectivealtruism.org/topics/randomized-controlled-trials"
			       "https://forum.effectivealtruism.org/topics/rationality"
			       "https://forum.effectivealtruism.org/topics/rationality-community"
			       "https://forum.effectivealtruism.org/topics/ready-research"
			       "https://forum.effectivealtruism.org/topics/reasoning-transparency"
			       "https://forum.effectivealtruism.org/topics/red-teaming"
			       "https://forum.effectivealtruism.org/topics/redwood-research"
			       "https://forum.effectivealtruism.org/topics/refuges"
			       "https://forum.effectivealtruism.org/topics/religion"
			       "https://forum.effectivealtruism.org/topics/replaceability"
			       "https://forum.effectivealtruism.org/topics/repugnant-conclusion"
			       "https://forum.effectivealtruism.org/topics/request-for-proposal"
			       "https://forum.effectivealtruism.org/topics/requests-closed"
			       "https://forum.effectivealtruism.org/topics/requests-open"
			       "https://forum.effectivealtruism.org/topics/research"
			       "https://forum.effectivealtruism.org/topics/research-agendas-questions-and-project-lists"
			       "https://forum.effectivealtruism.org/topics/research-careers"
			       "https://forum.effectivealtruism.org/topics/research-methods"
			       "https://forum.effectivealtruism.org/topics/research-summary"
			       "https://forum.effectivealtruism.org/topics/research-training-programs"
			       "https://forum.effectivealtruism.org/topics/resilient-food"
			       "https://forum.effectivealtruism.org/topics/resource-tradeoffs"
			       "https://forum.effectivealtruism.org/topics/rethink-charity"
			       "https://forum.effectivealtruism.org/topics/rethink-priorities"
			       "https://forum.effectivealtruism.org/topics/review-crosspost"
			       "https://forum.effectivealtruism.org/topics/risk-assessment"
			       "https://forum.effectivealtruism.org/topics/risk-aversion"
			       "https://forum.effectivealtruism.org/topics/risks-from-malevolent-actors"
			       "https://forum.effectivealtruism.org/topics/robin-hanson"
			       "https://forum.effectivealtruism.org/topics/role-impact"
			       "https://forum.effectivealtruism.org/topics/russia"
			       "https://forum.effectivealtruism.org/topics/s-risk"
			       "https://forum.effectivealtruism.org/topics/sci-foundation"
			       "https://forum.effectivealtruism.org/topics/spc-framework"
			       "https://forum.effectivealtruism.org/topics/safeguarding-liberal-democracy"
			       "https://forum.effectivealtruism.org/topics/sam-bankman-fried"
			       "https://forum.effectivealtruism.org/topics/samotsvety-forecasting"
			       "https://forum.effectivealtruism.org/topics/scalably-using-labour"
			       "https://forum.effectivealtruism.org/topics/science-and-technology-studies"
			       "https://forum.effectivealtruism.org/topics/scientific-progress"
			       "https://forum.effectivealtruism.org/topics/scope-neglect"
			       "https://forum.effectivealtruism.org/topics/scott-alexander"
			       "https://forum.effectivealtruism.org/topics/scout-mindset"
			       "https://forum.effectivealtruism.org/topics/self-care"
			       "https://forum.effectivealtruism.org/topics/semiconductors"
			       "https://forum.effectivealtruism.org/topics/sentience-1"
			       "https://forum.effectivealtruism.org/topics/sentience-institute"
			       "https://forum.effectivealtruism.org/topics/shrimp-welfare-project"
			       "https://forum.effectivealtruism.org/topics/simulation-argument"
			       "https://forum.effectivealtruism.org/topics/smallpox-eradication-programme"
			       "https://forum.effectivealtruism.org/topics/sogive"
			       "https://forum.effectivealtruism.org/topics/social-and-intellectual-movements"
			       "https://forum.effectivealtruism.org/topics/social-science-1"
			       "https://forum.effectivealtruism.org/topics/socially-responsible-investing"
			       "https://forum.effectivealtruism.org/topics/software-engineering"
			       "https://forum.effectivealtruism.org/topics/space-colonization"
			       "https://forum.effectivealtruism.org/topics/space-governance"
			       "https://forum.effectivealtruism.org/topics/spaced-repetition"
			       "https://forum.effectivealtruism.org/topics/spark-wave"
			       "https://forum.effectivealtruism.org/topics/speciesism"
			       "https://forum.effectivealtruism.org/topics/speeding-up-development"
			       "https://forum.effectivealtruism.org/topics/spillover-effects"
			       "https://forum.effectivealtruism.org/topics/squiggle"
			       "https://forum.effectivealtruism.org/topics/standards-and-regulation"
			       "https://forum.effectivealtruism.org/topics/stanford-existential-risks-initiative"
			       "https://forum.effectivealtruism.org/topics/stanislav-petrov"
			       "https://forum.effectivealtruism.org/topics/statistics"
			       "https://forum.effectivealtruism.org/topics/status-quo-bias"
			       "https://forum.effectivealtruism.org/topics/steven-pinker"
			       "https://forum.effectivealtruism.org/topics/strongminds"
			       "https://forum.effectivealtruism.org/topics/student-projects"
			       "https://forum.effectivealtruism.org/topics/students-for-high-impact-charity"
			       "https://forum.effectivealtruism.org/topics/subjective-wellbeing"
			       "https://forum.effectivealtruism.org/topics/suffering-focused-ethics"
			       "https://forum.effectivealtruism.org/topics/summer-program-on-applied-rationality-and-cognition"
			       "https://forum.effectivealtruism.org/topics/superintelligence"
			       "https://forum.effectivealtruism.org/topics/superintelligence-book"
			       "https://forum.effectivealtruism.org/topics/supervolcano"
			       "https://forum.effectivealtruism.org/topics/surveillance"
			       "https://forum.effectivealtruism.org/topics/surveys"
			       "https://forum.effectivealtruism.org/topics/survival-and-flourishing"
			       "https://forum.effectivealtruism.org/topics/suvita"
			       "https://forum.effectivealtruism.org/topics/swiss-existential-risk-initiative"
			       "https://forum.effectivealtruism.org/topics/systemic-change"
			       "https://forum.effectivealtruism.org/topics/tabletop-exercises"
			       "https://forum.effectivealtruism.org/topics/take-action"
			       "https://forum.effectivealtruism.org/topics/task-y"
			       "https://forum.effectivealtruism.org/topics/teaching-materials"
			       "https://forum.effectivealtruism.org/topics/technology-race"
			       "https://forum.effectivealtruism.org/topics/temporal-discounting"
			       "https://forum.effectivealtruism.org/topics/terrorism"
			       "https://forum.effectivealtruism.org/topics/the-humane-league"
			       "https://forum.effectivealtruism.org/topics/the-life-you-can-save"
			       "https://forum.effectivealtruism.org/topics/the-precipice"
			       "https://forum.effectivealtruism.org/topics/the-unjournal"
			       "https://forum.effectivealtruism.org/topics/theory-of-change"
			       "https://forum.effectivealtruism.org/topics/think-tanks"
			       "https://forum.effectivealtruism.org/topics/thinking-at-the-margin"
			       "https://forum.effectivealtruism.org/topics/time-of-perils"
			       "https://forum.effectivealtruism.org/topics/timing-of-philanthropy"
			       "https://forum.effectivealtruism.org/topics/tobacco-control"
			       "https://forum.effectivealtruism.org/topics/toby-ord"
			       "https://forum.effectivealtruism.org/topics/total-view"
			       "https://forum.effectivealtruism.org/topics/totalitarianism"
			       "https://forum.effectivealtruism.org/topics/tractability"
			       "https://forum.effectivealtruism.org/topics/training-for-good"
			       "https://forum.effectivealtruism.org/topics/trajectory-change"
			       "https://forum.effectivealtruism.org/topics/transformative-artificial-intelligence"
			       "https://forum.effectivealtruism.org/topics/transhumanism"
			       "https://forum.effectivealtruism.org/topics/translation"
			       "https://forum.effectivealtruism.org/topics/transparency"
			       "https://forum.effectivealtruism.org/topics/twitter"
			       "https://forum.effectivealtruism.org/topics/tyler-cowen"
			       "https://forum.effectivealtruism.org/topics/uk-policy"
			       "https://forum.effectivealtruism.org/topics/us-policy"
			       "https://forum.effectivealtruism.org/topics/ukraine"
			       "https://forum.effectivealtruism.org/topics/united-kingdom"
			       "https://forum.effectivealtruism.org/topics/united-nations-1"
			       "https://forum.effectivealtruism.org/topics/united-states"
			       "https://forum.effectivealtruism.org/topics/universal-basic-income"
			       "https://forum.effectivealtruism.org/topics/university-groups"
			       "https://forum.effectivealtruism.org/topics/utilitarianism"
			       "https://forum.effectivealtruism.org/topics/vaccines"
			       "https://forum.effectivealtruism.org/topics/valence"
			       "https://forum.effectivealtruism.org/topics/value-drift"
			       "https://forum.effectivealtruism.org/topics/value-lock-in"
			       "https://forum.effectivealtruism.org/topics/value-of-information"
			       "https://forum.effectivealtruism.org/topics/value-of-movement-growth"
			       "https://forum.effectivealtruism.org/topics/video-1"
			       "https://forum.effectivealtruism.org/topics/virtue-ethics"
			       "https://forum.effectivealtruism.org/topics/vitalik-buterin"
			       "https://forum.effectivealtruism.org/topics/volcanic-winter"
			       "https://forum.effectivealtruism.org/topics/volunteering"
			       "https://forum.effectivealtruism.org/topics/vulnerable-world-hypothesis"
			       "https://forum.effectivealtruism.org/topics/warning-shot"
			       "https://forum.effectivealtruism.org/topics/wave"
			       "https://forum.effectivealtruism.org/topics/weapons-of-mass-destruction"
			       "https://forum.effectivealtruism.org/topics/weekly-summaries-project"
			       "https://forum.effectivealtruism.org/topics/welfare-biology"
			       "https://forum.effectivealtruism.org/topics/welfare-economics"
			       "https://forum.effectivealtruism.org/topics/welfarism"
			       "https://forum.effectivealtruism.org/topics/wellbeing"
			       "https://forum.effectivealtruism.org/topics/what-we-owe-the-future"
			       "https://forum.effectivealtruism.org/topics/whole-brain-emulation"
			       "https://forum.effectivealtruism.org/topics/wikis"
			       "https://forum.effectivealtruism.org/topics/wild-animal-initiative"
			       "https://forum.effectivealtruism.org/topics/wild-animal-welfare"
			       "https://forum.effectivealtruism.org/topics/william-macaskill"
			       "https://forum.effectivealtruism.org/topics/windfall-clause"
			       "https://forum.effectivealtruism.org/topics/women-s-health-and-welfare"
			       "https://forum.effectivealtruism.org/topics/working-at-ea-vs-non-ea-orgs"
			       "https://forum.effectivealtruism.org/topics/workplace-advocacy"
			       "https://forum.effectivealtruism.org/topics/workplace-groups"
			       "https://forum.effectivealtruism.org/topics/workshops-retreats-summits"
			       "https://forum.effectivealtruism.org/topics/worldview-diversity-in-effective-altruism"
			       "https://forum.effectivealtruism.org/topics/writing-advice"))

(defun tlon-bae-insert-eawiki-slug ()
  "Insert an EA Wiki slug at point."
  (interactive)
  (insert (completing-read "URL: " tlon-bae-eawiki-slugs)))


(defun tlon-bae-insert-eawiki-url ()
  "Insert an EA Wiki slug at point."
  (interactive)
  (insert (completing-read "URL: " tlon-bae-eawiki-urls)))

(defun tlon-bae-initialize-revision (tag-title)
  "Initialize revision based on TAG-TITLE."
  ;; TODO: also open file with the original English version once
  ;; correspondence table is created
  (interactive "sTag title: ")
  (let* ((file-stem (file-name-with-extension
		     (concat "tag--" (tlon-core-slugify tag-title)) "md"))
	 (file-dir (file-name-concat ps/dir-dropbox "repos/BAE/translations/tags"))
	 (file (file-name-concat file-dir file-stem)))
    (if (file-exists-p file)
	(progn
	  (ps/window-split-if-unsplit)
	  (winum-select-window-2)
	  (find-file file))
      (user-error "File %s does not exist" file))
    (let ((default-directory file-dir))
      (when (magit-anything-staged-p)
	(user-error "There are staged changes. Please stash or commit them first."))
      (let ((new-branch (buffer-name (current-buffer))))
	(unless (magit-branch-p new-branch)
	  (magit-branch-create new-branch "main"))
	(magit-branch-checkout new-branch)
	(revert-buffer t t)
	(ispell-change-dictionary "espanol")
	(flyspell-buffer)
	(message "Now at branch %s" new-branch)))))

(defun tlon-bae-finalize-revision ()
  "Finalize BAE revision.
With point in a buffer that contains a finished BAE translation,
 perform the following operations:

1. `fill-region' on the entire buffer.
2. `save-buffer'.
3. Stage changes in local repo.
4. Commit with relevant message.
5. Push to remote.
6. Create pull request.
7. Optionally launch `github-review'."
  (interactive)
  (unless (string= (magit-get-current-branch) (buffer-name))
    (user-error "Buffer name does not match current branch"))
  (fill-region (point-min) (point-max))
  (save-buffer)
  (when (magit-anything-unstaged-p)
    (let* ((commit-summary-minus-filename "Revise ")
	   (commit-summary (concat
			    commit-summary-minus-filename
			    (truncate-string-to-width
			     (buffer-name)
			     (- git-commit-summary-max-length
				(length commit-summary-minus-filename))))))
      (magit-commit-create (list "-m" commit-summary))
      (call-interactively #'magit-push-current-to-pushremote)
      (sleep-for 2)
      (call-interactively #'forge-create-pullreq)
      (let ((comments (read-string "Any general comments? ")))
	(when (not (string= comments ""))
	  (forward-line 2)
	  (insert comments)))
      (forge-post-submit)
      (let ((magit-buffer "magit: BAE"))
	(with-current-buffer magit-buffer
	  (magit-refresh)
	  (forge-pull)
	  (goto-char (point-min))
	  (magit-section-show-level-3-all)
	  (search-forward commit-summary)))
      ;; (when (y-or-n-p "Open PR in `github-review'? ")
      ;; (github-review-forge-pr-at-point))
      ))
  (let ((new-branch "main"))
    (magit-branch-checkout new-branch)
    (message "Now at branch %s" new-branch))
  (magit-branch-delete (list (buffer-name)))
  (revert-buffer t t))

(defun tlon-bae-submit-comment-revisions ()
  "Submit PR comments and check out `main' branch."
  (interactive)
  (unless (eq major-mode 'github-review-mode)
    (error "Not in `github-review-mode'"))
  (github-review-comment)
  (save-buffer)
  (kill-buffer)
  (switch-to-buffer "magit: BAE")
  (let ((branch "main"))
    (magit-branch-checkout branch)
    (message "Submitted PR comments and checked out `%s' branch." branch)))

(defun tlon-bae-finalize-translation ()
  "Finalize BAE translation.
With point in a buffer that contains a finished BAE translation,
 perform the following operations:

1. `fill-region' on the entire buffer.
2. `save-buffer'.
3. stage changes in local repo.
4. prepopulate commit with relevant message."
  (interactive)
  (fill-region (point-min) (point-max))
  (save-buffer)
  (let ((file (buffer-file-name)))
    (let* ((commit-summary-minus-filename "Translate ")
	   (commit-summary (concat
			    commit-summary-minus-filename
			    (truncate-string-to-width
			     (buffer-name)
			     (- git-commit-summary-max-length
				(length commit-summary-minus-filename))))))
      (when (magit-anything-staged-p)
	(magit-unstage-all))
      (magit-stage-file file)
      (setq tlon-bae-git-commit-setup-message commit-summary)
      (magit-commit-create))))

(defvar tlon-bae-git-commit-setup-message
  ""
  "Message to pre-populate a commit.

This message is inserted by `tlon-bae-git-commit-setup', which is in
turn triggered by `git-commit-setup-hook'.")

(defun tlon-bae-git-commit-setup ()
  "Setup a commit message."
  (insert tlon-bae-git-commit-setup-message)
  (setq tlon-bae-git-commit-setup-message ""))

(add-hook 'git-commit-setup-hook 'tlon-bae-git-commit-setup)

(defun tlon-bae-update-and-reload ()
  "Update and rebuild `tlon'."
  (interactive)
  (elpaca-update 'tlon t)
  (load-library "tlon"))

(defun tlon-bae-initialize-original-revision ()
  "Open relevant docs for starting the revision of new translation."
  (interactive)
  (winum-select-window-2)
  (cl-multiple-value-bind (slug author title) (tlon-bae-format-file nil t)
    (find-file (file-name-concat ps/dir-dropbox "repos/BAE/originals/tags" slug))
    (winum-select-window-1)
    (advice-remove 'org-roam-node-find #'widen)
    (advice-remove 'org-roam-node-find #'ps/org-narrow-to-entry-and-children)
    (org-roam-node-find nil title)
    (advice-add 'org-roam-node-find :before #'widen)
    (advice-add 'org-roam-node-find :after #'ps/org-narrow-to-entry-and-children)
    (let ((eaf-slug (replace-regexp-in-string ".+?--\\(.*\\)\\.md" "\\1" slug)))
      (browse-url (format "https://forum.effectivealtruism.org/topics/%s" eaf-slug)))))

(defun tlon-bae-finalize-original-revision ()
  "Create issue with file at point and assign it to Leo."
  (interactive)
  (fill-region (point-min) (point-max))
  (save-buffer)
  (let* ((buffer-name (buffer-name))
	 (issue-name (format "Translate: `%s`" buffer-name)))
    (forge-create-issue)
    (insert issue-name)
    (read-string "Submit? ")
    (forge-post-submit)
    (sleep-for 5)
    (magit)
    (switch-to-buffer "magit: BAE")
    (magit-refresh)
    ;; (forge-pull)
    (goto-char (point-min))
    (magit-section-show-level-3-all)
    (search-forward issue-name)
    (call-interactively #'forge-edit-topic-assignees)
    (goto-char (point-min))
    (re-search-forward "Unstaged changes")
    (forward-line 1)))

(defun tlon-bae-search-github (&optional search-string)
  "Search for SEARCH-STRING in BAE GitHub issues and pull requests."
  (interactive "sSearch string: ")
  (let ((default-directory ps/dir-tlon-BAE-repo))
    (forge-search search-string)))

(defun tlon-bae-search-multi (search-string)
  "Search for SEARCH-STRING in BAE locally and issues and pull requests."
  (interactive "sSearch string: ")
  (tlon-bae-search-github search-string)
  (ps/window-split-if-unsplit)
  (other-window 1)
  (consult-ripgrep default-directory search-string))

(defun tlon-bae-commit-when-slug-at-point (&optional prefix)
  "Commit change when point is on a slug.
As the commit message, use 'PREFIX slug.md'. If the value of
PREFIX is not specificied, use 'Revise ' as the default."
  (interactive)
  (beginning-of-line)
  (re-search-forward "\\w+--.+?.md")
  (when-let ((file (match-string 0)))
    (let ((prefix (or prefix
		      "Revise ")))
      (magit-commit-create (list "-m" (concat prefix file)))
      (call-interactively #'magit-push-current-to-pushremote))))

(defun tlon-bae-apply-label (label)
  "Apply LABEL to topic at point.
Note that this only works for topics listed in the main buffer."
  (interactive)
  (let* ((topic (forge-get-topic (forge-topic-at-point)))
         (repo  (forge-get-repository topic))
         (crm-separator ","))
    (forge--set-topic-labels
     repo topic (list label))))

(defun tlon-bae-make-assignee (assignee)
  "Edit ASSIGNEE the assignee of topic at point."
  (interactive)
  (let* ((topic (forge-get-topic (forge-topic-at-point)))
         (repo  (forge-get-repository topic))
         (value (closql--iref topic 'assignees))
         (choices (mapcar #'cadr (oref repo assignees)))
         (crm-separator ","))
    (forge--set-topic-assignees
     repo topic
     (list assignee))))

;; 0th stage of process
(defun tlon-bae-label-awaiting-processing-and-assign-to-pablo ()
  "Label topic at point 'Awaiting processing' and assign it to Pablo."
  (interactive)
  (tlon-bae-apply-label "Awaiting processing")
  (tlon-bae-make-assignee "benthamite"))

;; 1st stage of process
(defun tlon-bae-label-awaiting-translation-and-assign-to-leo ()
  "Label topic at point 'Awaiting translation' and it assign to Leo."
  (interactive)
  (tlon-bae-apply-label "Awaiting translation")
  (tlon-bae-make-assignee "worldsaround"))

;; 2nd stage of process
(defun tlon-bae-label-awaiting-revision-and-assign-to-pablo ()
  "Label topic at point 'Awaiting revision' and assign it to Pablo."
  (interactive)
  (tlon-bae-apply-label "Awaiting revision")
  (tlon-bae-make-assignee "benthamite"))

;; 3rd stage of process
(defun tlon-bae-label-awaiting-reviewing-and-assign-to-leo ()
  "Label topic at point 'Awaiting reviewing' and it assign to Leo."
  (interactive)
  (tlon-bae-apply-label "Awaiting reviewing")
  (tlon-bae-make-assignee "worldsaround"))

;; 4th stage of process
(defun tlon-bae-label-awaiting-publication-and-assign-to-fede ()
  "Label topic at point 'Awaiting publication' and it assign to Fede."
  (interactive)
  (tlon-bae-apply-label "Awaiting publication")
  (tlon-bae-make-assignee "fstafforinid"))

(define-key github-review-mode-map (kbd "s-c") 'tlon-bae-submit-comment-revisions)
(define-key markdown-mode-map (kbd "s-f") 'tlon-bae-finalize-revision)

(provide 'tlon-bae)
;;; tlon-bae.el ends here