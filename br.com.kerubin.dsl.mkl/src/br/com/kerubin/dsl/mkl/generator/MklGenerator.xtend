/*
 * generated by Xtext 2.12.0
 */
package br.com.kerubin.dsl.mkl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class MklGenerator extends AbstractGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		
		generate(resource, fsa)
		
	}
	
	def generate(Resource resource, IFileSystemAccess2 fsa) {
		val javaGenerator = new JavaGenerator(resource, fsa)
		javaGenerator.generate
		
		val webGenerator = new WebGenerator(resource, fsa)
		webGenerator.generate 
	}

	
}
