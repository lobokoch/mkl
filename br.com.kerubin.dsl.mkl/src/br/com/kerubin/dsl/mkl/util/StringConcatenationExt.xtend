package br.com.kerubin.dsl.mkl.util

import org.eclipse.xtend2.lib.StringConcatenation

class StringConcatenationExt extends StringConcatenation {
	
	private static final String TAB = '\t'
	
	private StringConcatenation imports = new StringConcatenation()
	private String pakage_;
	
	def StringConcatenationExt add(String str) {
		newLine
		append(str)
		this
	}
	
	def StringConcatenationExt add(CharSequence str) {
		newLine
		append(str)
		this
	}
	
	def StringConcatenationExt add(String text, int index) {
		text.append(index)
		
		return this
	}
	
	def StringConcatenationExt add(CharSequence text, int index) {
		text.append(index)
		
		return this
	}
	
	def StringConcatenationExt addIndentAfter(CharSequence text, int index) {
		TAB.append(index)
		
		text.add(index)
		this
	}
	
	def StringConcatenationExt addIndent(CharSequence str, int index) {
		val text = new StringConcatenation()
		text.append(TAB)
		text.append(str, TAB)
		newLine
		add(text, index)
		this
	}
	
	def StringConcatenationExt addIndent(CharSequence str) {
		val text = new StringConcatenation()
		text.append(TAB)
		text.append(str, TAB)
		newLine
		append(text)
		this
	}
	
	def StringConcatenationExt concat(String str) {
		append(str)
		this
	}
	
	def StringConcatenationExt concat(CharSequence str) {
		append(str)
		this
	}
	
	def StringConcatenationExt ln() {
		newLine
		this
	}
	
	def StringConcatenationExt addImport(String import_) {
		imports.newLine
		if (!import_.startsWith('import')) {
			imports.append('import ')			
		}
		
		imports.append(import_)
		
		if (!import_.endsWith(';')) {
			imports.append(';')			
		}
		
		this
	}
	
	def StringConcatenation getImports() {
		imports
	}
	
	def void addPackage(String package_) {
		this.pakage_ = 'package ' + package_ + ';'
	}
	
	def StringConcatenation build() {
		val result = new StringConcatenationExt()
		
		if (pakage_ !== null) {
			result.add(pakage_)
		}
		
		if (imports.length > 0) {
			result.add(imports).ln
		}
		
		result.append(this)
		
		result
	}
}