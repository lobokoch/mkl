package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.BaseGenerator
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.model.Entity

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.test.TestUtils.*

class JavaEntityTestRepositoryGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.canGenerateRepository && it.canGenerateTest].forEach[generateRepository]
	}
	
	def generateRepository(Entity entity) {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toRepositoryNameForTest + '.java'
		generateFile(fileName, entity.generateEntityRepository)
	}
	
	def CharSequence generateEntityRepository(Entity entity) {
		
		'''
		package «entity.package»;
		
		import org.springframework.stereotype.Repository;
		
		@Repository
		public interface «entity.toRepositoryNameForTest» extends «entity.toRepositoryName» {
			
		}
		'''
	}
	
}