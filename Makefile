## See RELEASE_PROCEDURE.md

# Where to copy from
DRAFT=1.1-DRAFT
# Official release
RELEASE=1.1
# Semantic versioning
TAG=1.1.0
NEXT=1.2-DRAFT
# Prepare (but do not Publish!) the next version of https://zenodo.org/record/3541888
# then copy its DOI here so it can be included in generated HTML/PDF
DOI=10.5281/zenodo.4031327

all: dependencies release

# Check dependencies before we do the rest
dependencies: node_modules/.bin/makehtml
	scripts/schema-context.py --version
	node_modules/.bin/makehtml --version
	pandoc --version
	xelatex --version


clean:
	rm -rf release "docs/${RELEASE}/"

release: release/ro-crate-${TAG}.html release/ro-crate-${TAG}.pdf release/ro-crate-context-${TAG}.json release/ro-crate-metadata.json release/ro-crate-preview.html

# Install dependencies for node
node_modules/.bin/makehtml:
	npm i ro-crate

docs/${RELEASE}/:
	mkdir -p docs/${RELEASE}/

docs/${RELEASE}/index.md: docs/${RELEASE}/ docs/${DRAFT}/index.md
	sed s/${DRAFT}/${RELEASE}/g < docs/${DRAFT}/index.md > docs/${RELEASE}/index.md
	sed -i "/^<!-- NOTE: Before release.*/ d" docs/${RELEASE}/index.md
	sed -i "/^END NOTE -->/ d" docs/${RELEASE}/index.md
	sed -i "s/^* Status:.*/* Status: Recommendation/" docs/${RELEASE}/index.md
	sed -i "s/^* Published:.*/* Published: `date -I`/" docs/${RELEASE}/index.md
	sed -i "s,^* Cite as:.*,* Cite as: <https://doi.org/${DOI}> (this version)," docs/${RELEASE}/index.md

docs/${RELEASE}/ro-crate-metadata.json: docs/${DRAFT}/ro-crate-metadata.json
	sed s/${DRAFT}/${RELEASE}/g < docs/${DRAFT}/ro-crate-metadata.json > docs/${RELEASE}/ro-crate-metadata.json
	sed -i "s/UNPUBLISHED/`date -I`/g" docs/${RELEASE}/ro-crate-metadata.json
	sed -i "s/TAG/${TAG}/g" docs/${RELEASE}/ro-crate-metadata.json
	sed -i "s,DOI,${DOI},g" docs/${RELEASE}/ro-crate-metadata.json
	rm -f docs/${RELEASE}/ro-crate-metadata.jsonld
	ln -s ro-crate-metadata.json docs/${RELEASE}/ro-crate-metadata.jsonld

docs/${RELEASE}/ro-crate-preview.html: dependencies docs/${RELEASE}/ro-crate-metadata.json
	node_modules/.bin/makehtml docs/${RELEASE}/ro-crate-metadata.json

docs/${RELEASE}/context.json: dependencies docs/${RELEASE}/ scripts/schema-context.py
	scripts/schema-context.py ${RELEASE} ${TAG} > docs/${RELEASE}/context.json

release/:
	mkdir -p release

release/ro-crate-${TAG}.html: dependencies release/ docs/${RELEASE}/index.md
	egrep -v '^{:(\.no_)?toc}' docs/${RELEASE}/index.md | \
	pandoc --standalone --number-sections --toc --section-divs \
	  --metadata pagetitle="RO-Crate Metadata Specification ${RELEASE}" \
	  --from=markdown+gfm_auto_identifiers -o release/ro-crate-${TAG}.html

release/ro-crate-${TAG}.pdf: dependencies release/ docs/${RELEASE}/index.md
	egrep -v '^{:(\.no_)?toc}' docs/${RELEASE}/index.md | \
	pandoc --pdf-engine xelatex --variable=hyperrefoptions:colorlinks=true,allcolors=blue \
	  --variable papersize=a4 \
	  --number-sections --toc  --metadata pagetitle="RO-Crate Metadata Specification ${RELEASE}" \
	  --from=markdown+gfm_auto_identifiers -o release/ro-crate-${TAG}.pdf

release/ro-crate-context-${TAG}.json: dependencies release/ docs/${RELEASE}/context.json
	cp docs/${RELEASE}/context.json release/ro-crate-context-${TAG}.json

release/ro-crate-metadata.json: dependencies release/ docs/${RELEASE}/ro-crate-metadata.json
	cp docs/${RELEASE}/ro-crate-metadata.json release/ro-crate-metadata.json

release/ro-crate-preview.html: dependencies release/ docs/${RELEASE}/ro-crate-preview.html
	cp docs/${RELEASE}/ro-crate-preview.html release/ro-crate-preview.html
