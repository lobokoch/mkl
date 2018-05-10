package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaEntityRepositoryGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateRepository]
	}
	
	def generateRepository(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toRepositoryName + '.java'
		generateFile(fileName, entity.generateEntityRepository)
	}
	
	def CharSequence generateEntityRepository(Entity entity) {
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		'''
		package «entity.package»;
		
		import org.springframework.data.jpa.repository.JpaRepository;
		«IF entity.isBaseRepository»
		import org.springframework.data.repository.NoRepositoryBean;
		
		@NoRepositoryBean
		«ELSE»
		
		«ENDIF»
		public interface «entity.toRepositoryName» extends JpaRepository<«entity.toEntityName», «idType»> {
		
		}
		'''
	}
	
}