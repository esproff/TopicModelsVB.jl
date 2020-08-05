mutable struct Document
	"Document mutable struct"

	"terms:   A vector{Int} containing keys for the Corpus vocab Dict."
	"counts:  A Vector{Int} denoting the counts of each term in the Document."
	"readers: A Vector{Int} denoting the keys for the Corpus users Dict."
	"ratings: A Vector{Int} denoting the ratings for each reader in the Document."
	"title:   The title of the document (String)."

	terms::Vector{Int}
	counts::Vector{Int}
	readers::Vector{Int}
	ratings::Vector{Int}
	title::String

	function Document(;terms=[], counts=ones(length(terms)), readers=[], ratings=ones(length(readers)), title="")
		doc = new(terms, counts, readers, ratings, title)
		check_doc(doc)
		return doc
	end
end

### Document outer constructors.
Document(terms) = Document(terms=terms)

struct DocumentError <: Exception
    msg::String
end

Base.showerror(io::IO, e::DocumentError) = print(io, "DocumentError: ", e.msg)

function check_doc(doc::Document)
	"Check Document parameters."

	all(doc.terms .> 0)									|| throw(DocumentError("All terms must be positive integers."))
	all(doc.counts .> 0)								|| throw(DocumentError("All counts must be positive integers."))
	isequal(length(doc.terms), length(doc.counts))		|| throw(DocumentError("The terms and counts vectors must have the same length."))
	all(doc.readers .> 0)								|| throw(DocumentError("All readers must be positive integers."))
	all(doc.ratings .> 0)								|| throw(DocumentError("All ratings must be positive integers."))
	isequal(length(doc.readers), length(doc.ratings))	|| throw(DocumentError("The readers and ratings vectors must have the same length."))
 	nothing
 end

mutable struct Corpus
	"Corpus mutable struct."

	"docs:  A Vector{Document} containing the documents which belong to the Corpus."
	"vocab: A Dict{Int, String} containing a mapping term Int (key) => term String (value)."
	"users: A Dict{Int, String} containing a mapping user Int (key) => user String (value)."

	docs::Vector{Document}
	vocab::Dict{Int, String}
	users::Dict{Int, String}

	function Corpus(;docs=Document[], vocab=[], users=[])
		isa(vocab, Vector) && (vocab = Dict(vkey => term for (vkey, term) in enumerate(string.(vocab))))
		isa(users, Vector) && (users = Dict(ukey => user for (ukey, user) in enumerate(string.(users))))

		corp = new(docs, vocab, users)
		check_docs(corp)

		all(collect(keys(corp.vocab)) .> 0) || throw(CorpusError("All vocab keys must be positive integers."))
		all(collect(keys(corp.users)) .> 0) || throw(CorpusError("All user keys must be positive integers."))
		return corp
	end
end

### Corpus outer constructors.
Corpus(docs::Vector{Document}) = Corpus(docs=docs)
Corpus(docs::Vector{Document}; vocab=[], users=[]) = Corpus(docs=docs, vocab=vocab, users=users)
Corpus(doc::Document) = Corpus(docs=[doc])
Corpus(doc::Document; vocab=[], users=[]) = Corpus(docs=[doc], vocab=vocab, users=users)

struct CorpusError <: Exception
    msg::String
end

Base.showerror(io::IO, e::CorpusError) = print(io, "CorpusError: ", e.msg)

 function check_docs(corp::Corpus)
 	"Check Corpus documents."

	for (d, doc) in enumerate(corp)
		try
			check_doc(doc)
		catch
			throw(CorpusError("Document $d failed check."))
		end
	end
end

function check_corp(corp::Corpus)
	"Check Corpus parameters."

	check_docs(corp)

	all(collect(keys(corp.vocab)) .> 0) || throw(CorpusError("All vocab keys must be positive integers."))
	all(collect(keys(corp.users)) .> 0) || throw(CorpusError("All user keys must be positive integers."))

	issubset(vcat([doc.terms for doc in corp]...), keys(corp.vocab)) 		|| throw(CorpusError("Documents contain term keys not found in corpus vocabulary (see fixcorp! function)."))
	issubset(vcat([doc.readers for doc in corp]...), keys(corp.users)) 		|| throw(CorpusError("Documents contain user keys not found in corpus users (see fixcorp! function)."))
	(length(corp.vocab) == maximum(push!(collect(keys(corp.vocab)), 0)))	|| throw(CorpusError("Corpus vocab keys must form unit range starting at 1 (see fixcorp! function)."))
	(length(corp.users) == maximum(push!(collect(keys(corp.users)), 0)))	|| throw(CorpusError("Corpus user keys must form unit range starting at 1 (see fixcorp! function)."))
	nothing
end

Base.show(io::IO, doc::Document) = print(io, "Document with:\n * $(length(doc.terms)) terms\n * $(length(doc.readers)) readers")
Base.length(doc::Document) = length(doc.terms)
Base.size(doc::Document) = sum(doc.counts)
Base.in(doc::Document, corp::Corpus) = in(doc, corp.docs)
Base.isempty(doc::Document) = length(doc) == 0

Base.show(io::IO, corp::Corpus) = print(io, "Corpus with:\n * $(length(corp)) docs\n * $(length(corp.vocab)) vocab\n * $(length(corp.users)) users")
Base.iterate(corp::Corpus, d=1) = Base.iterate(corp.docs, d)
Base.push!(corp::Corpus, doc::Document) = push!(corp.docs, doc)
Base.pop!(corp::Corpus) = pop!(corp.docs)
Base.pushfirst!(corp::Corpus, doc::Document) = pushfirst!(corp.docs, doc)
Base.pushfirst!(corp::Corpus, docs::Vector{Document}) = pushfirst!(corp.docs, docs)
Base.popfirst!(corp::Corpus) = popfirst!(corp.docs)
Base.insert!(corp::Corpus, d::Int, doc::Document) = insert!(corp.docs, d, doc)
Base.deleteat!(corp::Corpus, d::Int) = deleteat!(corp.docs, d)
Base.deleteat!(corp::Corpus, doc_indices::Vector{Int}) = deleteat!(corp.docs, doc_indices)
Base.deleteat!(corp::Corpus, doc_indices::UnitRange{Int}) = deleteat!(corp.docs, doc_indices)
Base.getindex(corp::Corpus, d::Int) = getindex(corp.docs, d)
Base.getindex(corp::Corpus, doc_indices::Vector{Int}) = getindex(corp.docs, doc_indices)
Base.getindex(corp::Corpus, doc_indices::UnitRange{Int}) = getindex(corp.docs, doc_indices)
Base.getindex(corp::Corpus, doc_bool::Vector{Bool}) = getindex(corp.docs, doc_bool)
Base.setindex!(corp::Corpus, doc::Document, d::Int) = setindex!(corp.docs, doc, d)
Base.setindex!(corp::Corpus, docs::Vector{Document}, doc_indices::Vector{Int}) = setindex!(corp.docs, docs, doc_indices)
Base.setindex!(corp::Corpus, docs::Vector{Document}, doc_indices::UnitRange{Int}) = setindex!(corp.docs, docs, doc_indices)
Base.findfirst(corp::Corpus, doc::Document) = findfirst(corp.docs, doc)
Base.findall(corp::Corpus, docs::Vector{Document}) = findall((in)corp.docs, docs)
Base.findall(corp::Corpus, doc::Document) = findall(corp, [doc])
Base.length(corp::Corpus) = length(corp.docs)
Base.size(corp::Corpus) = (length(corp), length(corp.vocab), length(corp.users))
Base.copy(corp::Corpus) = Corpus(docs=copy(corp.docs), vocab=copy(corp.vocab), users=copy(corp.users))
Base.lastindex(corp::Corpus) = length(corp)
Base.enumerate(corp::Corpus) = enumerate(corp.docs)
Base.unique(corp::Corpus) = Corpus(docs=unique(corp.docs), vocab=corp.vocab, users=corp.users)

function showdocs(corp::Corpus, docs::Vector{Document})
	"Display document(s) in readable format."

	issubset(vcat([doc.terms for doc in docs]...), keys(corp.vocab)) || throw(DocumentError("Some documents contain term keys not found in Corpus vocabulary."))

	for (n, doc) in enumerate(docs)
		if !isempty(doc.title)
			@juliadots "$(doc.title)\n"

		else
			@juliadots "Document\n"
		end

		if !isempty(doc)
			println(Crayon(bold=false), join([corp.vocab[vkey] for vkey in doc.terms], " "))

		else
			println()
		end

		if n < length(docs)
			println()
		end
	end
end

function showdocs(corp::Corpus, doc_indices::Vector{<:Integer})
	"Display document(s) in readable format."

	issubset(doc_indices, 1:length(corp))											|| throw(CorpusError("Some document indices outside corpus range."))
	issubset(vcat([doc.terms for doc in corp[doc_indices]]...), keys(corp.vocab))	|| throw(DocumentError("Some documents contain term keys not found in Corpus vocabulary."))

	for (n, d) in enumerate(doc_indices)
		@juliadots "Document $d\n"
		
		if !isempty(corp[d].title)
			@juliadots "$(corp[d].title)\n"
		end

		if !isempty(corp[d])
			println(Crayon(bold=false), join([corp.vocab[vkey] for vkey in corp[d].terms], " "))

		else
			println()
		end

		if n < length(doc_indices)
			println()
		end
	end
end

showdocs(corp::Corpus, doc::Document) = showdocs(corp, [doc]) 
showdocs(corp::Corpus, doc_range::UnitRange{<:Integer}) = showdocs(corp, collect(doc_range))
showdocs(corp::Corpus, d::Integer) = showdocs(corp, [d])
showdocs(corp::Corpus) = showdocs(corp, 1:length(corp))

function showtitles(corp::Corpus, docs::Vector{Document})
	"Display document title(s) in readable format."

	issubset(vcat([doc.terms for doc in docs]...), keys(corp.vocab)) || throw(DocumentError("Some documents contain term keys not found in Corpus vocabulary."))

	for doc in docs
		print(Crayon(foreground=:yellow, bold=true), " • ")

		if !isempty(doc.title)
			println(Crayon(foreground=:white, bold=false), "$(doc.title)")

		else
			println(Crayon(foreground=:white, bold=true), "Document")
		end
	end
end

function showtitles(corp::Corpus, doc_indices::Vector{<:Integer})
	"Display document title(s) in readable format."

	issubset(doc_indices, 1:length(corp))											|| throw(CorpusError("Some document indices outside corpus range."))
	issubset(vcat([doc.terms for doc in corp[doc_indices]]...), keys(corp.vocab))	|| throw(DocumentError("Some documents contain term keys not found in Corpus vocabulary."))
	
	for d in doc_indices
		print(Crayon(foreground=:yellow, bold=true), " • ")

		if !isempty(corp[d].title)
			print(Crayon(foreground=:white, bold=true), "Document $d ")
			println(Crayon(foreground=:white, bold=false), "$(corp[d].title)")

		else
			println(Crayon(foreground=:white, bold=true), "Document $d")
		end
	end
end

showtitles(corp::Corpus, doc::Document) = showtitles(corp, [doc]) 
showtitles(corp::Corpus, doc_range::UnitRange{<:Integer}) = showtitles(corp, collect(doc_range))
showtitles(corp::Corpus, d::Integer) = showtitles(corp, [d])
showtitles(corp::Corpus) = showtitles(corp, 1:length(corp))

getvocab(corp::Corpus) = sort(collect(values(corp.vocab)))
getusers(corp::Corpus) = sort(collect(values(corp.users)))

function readcorp(;docfile::String="", vocabfile::String="", userfile::String="", titlefile::String="", delim::Char=',', counts::Bool=false, readers::Bool=false, ratings::Bool=false)	
	"Load a Corpus object from text file(s)."

	(ratings <= readers) || (ratings = false; warn("Ratings require readers, ratings switch set to false."))
	(!isempty(docfile) | isempty(titlefile)) || warn("No docfile, titles will not be assigned.")

	corp = Corpus()
	if !isempty(docfile)
		docs = open(docfile)
		doc_kwargs = [:terms, :counts, :readers, :ratings]	
		
		for (d, doc_block) in enumerate(Iterators.partition(readlines(docs), counts + readers + ratings + 1))
			try 
				doc_lines = Vector{Int}[[parse(Int, p) for p in split(line, delim)] for line in doc_block]			
				doc_input = zip(doc_kwargs[[true, counts, readers, ratings]], doc_lines)
				push!(corp, Document(;doc_input...))
			
			catch
				throw(CorpusError("Document $d beginning on line $((d - 1) * (counts + readers + ratings) + d) failed to load."))
			end
		end

	else
		warn("No docfile, topic models cannot be trained without documents.")
	end

	if !isempty(vocabfile)
		vocab = readdlm(vocabfile, '\t', comments=false)
		vkeys = vocab[:,1]
		terms = [string(j) for j in vocab[:,2]]
		corp.vocab = Dict{Int, String}(zip(vkeys, terms))
		all(collect(keys(corp.vocab)) .> 0) || throw(CorpusError("All vocab keys must be positive integers."))
	end

	if !isempty(userfile)
		users = readdlm(userfile, '\t', comments=false)
		ukeys = users[:,1]
		users = [string(u) for u in users[:,2]]
		corp.users = Dict{Int, String}(zip(ukeys, users))
		all(collect(keys(corp.users)) .> 0) || throw(CorpusError("All user keys must be positive integers."))
	end

	if !isempty(titlefile)
		titles = readdlm(titlefile, '\n', String)
		for (d, doc) in enumerate(corp)
			doc.title = titles[d]
		end
	end

	return corp
end

function readcorp(corp_symbol::Symbol)
	"Shortcuts for prepackaged corpora."

	datasets_path = joinpath((@__DIR__)[1:end-3], "datasets")

	if corp_symbol == :nsf
		docfile = joinpath(datasets_path, "nsf/nsfdocs.txt")
		vocabfile = joinpath(datasets_path, "nsf/nsfvocab.txt")
		titlefile = joinpath(datasets_path, "nsf/nsftitles.txt")
		corp = readcorp(docfile=docfile, vocabfile=vocabfile, titlefile=titlefile, counts=true)

	elseif corp_symbol == :citeu
		docfile = joinpath(datasets_path, "citeu/citeudocs.txt")
		vocabfile = joinpath(datasets_path, "citeu/citeuvocab.txt")
		userfile = joinpath(datasets_path, "citeu/citeuusers.txt")
		titlefile = joinpath(datasets_path, "citeu/citeutitles.txt")
		corp = readcorp(docfile=docfile, vocabfile=vocabfile, userfile=userfile, titlefile=titlefile, counts=true, readers=true)

	else
		println("Included corpora:\n:nsf\n:citeu")
		corp = nothing
	end

	return corp
end

function writecorp(corp::Corpus; docfile::String="", vocabfile::String="", userfile::String="", titlefile::String="", delim::Char=',', counts::Bool=false, readers::Bool=false, ratings::Bool=false)	
	"Write a corpus."

	(ratings <= readers) || (ratings = false; warn("Ratings require readers, ratings switch set to false."))

	if !isempty(docfile)
		doc_kwargs = [:counts, :readers, :ratings]
		doc_kwargs = doc_kwargs[[counts, readers, ratings]]
		docfile = open(docfile, "w")
		for doc in corp
			write(docfile, join(doc.terms, delim), '\n')
			for arg in doc_kwargs
				write(docfile, join(doc.(arg), delim), '\n')
			end
		end
		close(docfile)
	end

	if !isempty(vocabfile)
		vkeys = sort(collect(keys(corp.vocab)))
		vocab = zip(vkeys, [corp.vocab[vkey] for vkey in vkeys])
		writedlm(vocabfile, vocab)
	end

	if !isempty(userfile)
		ukeys = sort(collect(keys(corp.users)))
		users = zip(ukeys, [corp.users[ukey] for ukey in ukeys])
		writedlm(userfile, users)
	end

	if !isempty(titlefile)
		writedlm(titlefile, [doc.title for doc in corp])
	end
	nothing
end

### The _corp and _docs functions are designed to provide safe methods for modifying corpora.
### The _corp functions only meaningfully modify the Corpus object.
### In so far as the _corp functions modify Document objects, it only amounts to a possible relabeling of the keys in the documents.
### The _doc functions only modify the Document objects attached the corpus, they do not modify the Corpus object.
### The exception to the above rule is the stop_corp! function, which removes stop words from both the Corpus vocab dictionary and associated keys in the documents.

function abridge_corp!(corp::Corpus, n::Integer=0)
	"All terms which appear less than n times in the corpus are removed from all documents."

	doc_vkeys = Set(vcat([doc.terms for doc in unique(corp)]...))
	vocab_count = Dict(Int(j) => 0 for j in doc_vkeys)
	
	for doc in unique(corp), (j, c) in zip(doc.terms, doc.counts)
		vocab_count[j] += c
	end

	for doc in unique(corp)
		keep = Bool[vocab_count[j] >= n for j in doc.terms]
		doc.terms = doc.terms[keep]
		doc.counts = doc.counts[keep]
	end
	nothing
end

function alphabetize_corp!(corp::Corpus; vocab::Bool=true, users::Bool=true)
	"Alphabetize vocab and/or user dictionaries."

	if vocab
		vkeys = sort(collect(keys(corp.vocab)))
		terms = sort(collect(values(corp.vocab)))

		vkey_map = Dict(vkey_old => vkey_new for (vkey_old, vkey_new) in zip(vkeys, vkeys[sortperm(sortperm([corp.vocab[vkey] for vkey in vkeys]))]))
		corp.vocab = Dict(vkey => term for (vkey, term) in zip(vkeys, terms))

		for doc in unique(corp)
			doc.terms = [vkey_map[j] for j in doc.terms]
		end
	end

	if users
		ukeys = sort(collect(keys(corp.users)))
		users = sort(collect(values(corp.users)))

		ukey_map = Dict(ukey_old => ukey_new for (ukey_old, ukey_new) in zip(ukeys, ukeys[sortperm(sortperm([corp.users[ukey] for ukey in ukeys]))]))
		corp.users = Dict(ukey => user for (ukey, user) in zip(ukeys, users))

		for doc in unique(corp)
			doc.readers = [ukey_map[r] for r in doc.readers]
		end
	end
	nothing
end

function clip_corp!(corp::Corpus; vocab::Bool=true, users::Bool=true)
	"Keep top n terms."
	nothing
end

function remove_terms!(corp::Corpus; terms::Vector{String}=[])
	"Vocab keys for specified terms are removed from all documents."

	remove_keys = filter(vkey -> lowercase(corp.vocab[vkey]) in terms, collect(keys(corp.vocab)))
	
	for doc in unique(corp)
		keep = Bool[!(j in remove_keys) for j in doc.terms]
		doc.terms = doc.terms[keep]
		doc.counts = doc.counts[keep]
	end
	nothing
end

remove_terms!(corp::Corpus, term::String) = remove_vocab!(corp, terms=[term])

function compact_corp!(corp::Corpus; vocab::Bool=true, users::Bool=true)
	"Relabel vocab and/or user keys so that they form a unit range starting at 1."

	if vocab
		vkeys = sort(collect(keys(corp.vocab)))
		vkey_map = Dict(vkey => v for (v, vkey) in enumerate(vkeys))
		corp.vocab = Dict(vkey_map[vkey] => corp.vocab[vkey] for vkey in keys(corp.vocab))

		for doc in unique(corp)
			doc.terms = [vkey_map[vkey] for vkey in doc.terms]
		end
	end

	if users
		ukeys = sort(collect(keys(corp.users)))
		ukey_map = Dict(ukey => u for (u, ukey) in enumerate(ukeys))
		corp.users = Dict(ukey_map[ukey] => corp.users[ukey] for ukey in keys(corp.users))

		for doc in unique(corp)
			doc.readers = [ukey_map[ukey] for ukey in doc.readers]
		end
	end
	nothing
end

function condense_corp!(corp::Corpus)
	"Ignore term order in documents."
	"Multiple seperate occurrences of terms are stacked and their associated counts increased."

	for doc in unique(corp)
		docdict = Dict(j => 0 for j in doc.terms)
		for (j, c) in zip(doc.terms, doc.counts)
			docdict[j] += c
		end

		doc.terms = collect(keys(docdict))
		doc.counts = collect(values(docdict))
	end
	nothing
end

function pad_corp!(corp::Corpus; vocab::Bool=true, users::Bool=true)
	"Enter generic values for vocab and/or user keys which appear in documents but not in the vocab/user dictionaries."

	if vocab
		doc_vkeys = Set(vcat([doc.terms for doc in corp]...))
		for vkey in setdiff(doc_vkeys, keys(corp.vocab))
			corp.vocab[vkey] = string(join(["#term", vkey]))
		end
	end

	if users
		doc_ukeys = Set(vcat([doc.readers for doc in corp]...))
		for ukey in setdiff(doc_ukeys, keys(corp.users))
			corp.users[ukey] = string(join(["#user", ukey]))
		end
	end
	nothing
end

function remove_empty_docs!(corp::Corpus)
	"Documents with no terms are removed from the corpus."

	keep = Bool[length(doc.terms) > 0 for doc in corp]
	corp.docs = corp[keep]
	nothing
end

function remove_redundant!(corp::Corpus; vocab::Bool=true, users::Bool=true)
	"Remove vocab and/or user keys which map to redundant values."
	"Reassign Document term and/or reader keys."

	if vocab
		vkey_map = Dict()
		vocab_dict_inverse = Dict()
		vkeys = sort(collect(keys(corp.vocab)))
		for vkey in vkeys
			if corp.vocab[vkey] in keys(vocab_dict_inverse)
				vkey_map[vkey] = vocab_dict_inverse[corp.vocab[vkey]]
				delete!(corp.vocab, vkey)

			else
				vkey_map[vkey] = vkey
				vocab_dict_inverse[corp.vocab[vkey]] = vkey
			end
		end

		for doc in unique(corp)
			doc.terms = [vkey_map[vkey] for vkey in doc.terms]
		end
	end

	if users
		ukey_map = Dict()
		users_dict_inverse = Dict()
		ukeys = sort(collect(keys(corp.users)))
		for ukey in ukeys
			if corp.users[ukey] in keys(users_dict_inverse)
				ukey_map[ukey] = users_dict_inverse[corp.users[ukey]]
				delete!(corp.users, ukey)

			else
				ukey_map[ukey] = ukey
				users_dict_inverse[corp.users[ukey]] = ukey
			end
		end

		for doc in unique(corp)
			doc.readers = [ukey_map[ukey] for ukey in doc.readers]
		end
	end
	nothing
end

function stop_corp!(corp::Corpus)
	"Filter stop words in the associated corpus."

	datasets_path = joinpath((@__DIR__)[1:end-3], "datasets")

	stop_words = vec(readdlm(joinpath(datasets_path, "stopwords.txt"), String))
	stop_keys = filter(vkey -> lowercase(corp.vocab[vkey]) in stop_words, collect(keys(corp.vocab)))
	
	for doc in unique(corp)
		keep = Bool[!(j in stop_keys) for j in doc.terms]
		doc.terms = doc.terms[keep]
		doc.counts = doc.counts[keep]
	end
	nothing
end

function trim_corp!(corp::Corpus; vocab::Bool=true, users::Bool=true)
	"Those keys which appear in the corpus vocab and/or user dictionaries but not in any of the documents are removed from the corpus."

	if vocab
		doc_vkeys = Set(vcat([doc.terms for doc in corp]...))
		corp.vocab = Dict(vkey => corp.vocab[vkey] for vkey in intersect(keys(corp.vocab), doc_vkeys))
	end

	if users
		doc_ukeys = Set(vcat([doc.readers for doc in corp]...))
		corp.users = Dict(ukey => corp.users[ukey] for ukey in intersect(keys(corp.users), doc_ukeys))
	end
	nothing
end

function trim_docs!(corp::Corpus; terms::Bool=true, readers::Bool=true)
	"Those vocab and/or user keys which appear in documents but not in the corpus dictionaries are removed from the documents."

	if terms
		doc_vkeys = Set(vcat([doc.terms for doc in corp]...))
		bogus_vkeys = setdiff(doc_vkeys, keys(corp.vocab))
		for doc in unique(corp)
			keep = Bool[!(j in bogus_vkeys) for j in doc.terms]
			doc.terms = doc.terms[keep]
			doc.counts = doc.counts[keep]
		end
	end

	if readers
		doc_ukeys = Set(vcat([doc.readers for doc in corp]...))
		bogus_ukeys = setdiff(doc_ukeys, keys(corp.users))
		for doc in unique(corp)
			keep = Bool[!(u in bogus_ukeys) for u in doc.readers]
			doc.readers = doc.readers[keep]
			doc.ratings = doc.ratings[keep]
		end
	end
	nothing
end

function fixcorp!(corp::Corpus; vocab::Bool=true, users::Bool=true, abridge::Integer=0, alphabetize::Bool=false, condense::Bool=false, pad::Bool=false, remove_empty_docs::Bool=false, remove_redundant::Bool=false, remove_terms::Vector{String}=String[], stop::Bool=false, trim::Bool=false)
	"Generic function to ensure that a Corpus object can be loaded into a TopicModel object."
	"Either pad_corp! or trim_docs!."
	"compact_corp!."
	"Contains other optional keyword arguments."

	check_docs(corp)

	all(collect(keys(corp.vocab)) .> 0) || throw(CorpusError("All vocab keys must be positive integers."))
	all(collect(keys(corp.users)) .> 0) || throw(CorpusError("All user keys must be positive integers."))
 
	pad ? pad_corp!(corp) : trim_docs!(corp)

	remove_redundant			&& remove_redundant!(corp)
	condense 					&& condense_corp!(corp)
	abridge > 0 				&& abridge_corp!(corp, abridge)
	pad 						&& pad_corp!(corp, vocab=vocab, users=users)
	length(remove_terms) > 0	&& remove_terms!(corp, terms=remove_terms)
	stop 						&& stop_corp!(corp)
	trim 						&& trim_corp!(corp, vocab=vocab, users=users)
	alphabetize 				&& alphabetize_corp!(corp, vocab=vocab, users=users)
	remove_empty_docs 			&& remove_empty_docs!(corp)

	compact_corp!(corp)
	nothing
end
