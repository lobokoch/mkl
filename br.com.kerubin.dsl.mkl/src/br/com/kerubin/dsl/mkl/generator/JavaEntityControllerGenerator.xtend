package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity

class JavaEntityControllerGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateController]
	}
	
	def generateController(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toControllerName + '.java'
		generateFile(fileName, entity.generateEntityController)
	}
	
	def CharSequence generateEntityController(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val entityServiceVar = entity.toServiceName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		'''
		package «entity.package»;
		
		import java.util.List;
		import java.util.stream.Collectors;
		
		import javax.validation.Valid;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.web.bind.annotation.RestController;
		import org.springframework.web.bind.annotation.RequestMapping;
		import org.springframework.web.bind.annotation.ResponseStatus;
		import org.springframework.http.ResponseEntity;
		import org.springframework.http.HttpStatus;
		
		import org.springframework.web.bind.annotation.PathVariable;
		import org.springframework.web.bind.annotation.RequestBody;
		import org.springframework.web.bind.annotation.PostMapping;
		import org.springframework.web.bind.annotation.GetMapping;
		import org.springframework.web.bind.annotation.PutMapping;
		import org.springframework.web.bind.annotation.DeleteMapping;
		
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		«service.importPageResult»
		
		
		@RestController
		@RequestMapping("entities/«entityDTOVar»")
		public class «entity.toControllerName» {
			
			@Autowired
			private «entity.toServiceName» «entityServiceVar»;
			
			@Autowired
			«entityDTOName»DTOConverter «entityDTOVar»DTOConverter;
			
			@PostMapping
			public ResponseEntity<«entityDTOName»> create(@Valid @RequestBody «entityDTOName» «entityDTOVar») {
				«entityName» «entityVar» = «entityServiceVar».create(«entityDTOVar»DTOConverter.convert(«entityDTOVar»));
				return ResponseEntity.status(HttpStatus.CREATED).body(«entityDTOVar»DTOConverter.convert(«entityVar»));
			}
			
			@GetMapping("/{«idVar»}")
			public ResponseEntity<«entityDTOName»> read(@PathVariable «idType» «idVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».read(«idVar»);
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.convert(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@PutMapping("/{«idVar»}")
			public ResponseEntity<«entityDTOName»> update(@PathVariable «idType» «idVar», @Valid @RequestBody «entityDTOName» «entityDTOVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».update(«idVar», «entityDTOVar»DTOConverter.convert(«entityDTOVar»));
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.convert(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@DeleteMapping("/{«idVar»}")
			@ResponseStatus(HttpStatus.NO_CONTENT)
			public void delete(@PathVariable «idType» «idVar») {
				«entityServiceVar».delete(«idVar»);
			}
			
			@GetMapping
			public PageResult<«entityDTOName»> list(Pageable pageable) {
				Page<«entityName»> page = «entityServiceVar».list(pageable);
				List<«entityDTOName»> content = page.getContent().stream().map(pe -> «entityDTOVar»DTOConverter.convert(pe)).collect(Collectors.toList());
				PageResult<«entityDTOName»> pageResult = new PageResult<>(content, page.getNumber(), page.getSize(), page.getTotalElements());
				return pageResult;
			}
			
		}
		'''
	}
	
}