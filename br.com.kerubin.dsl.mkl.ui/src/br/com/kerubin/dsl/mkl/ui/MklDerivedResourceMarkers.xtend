package br.com.kerubin.dsl.mkl.ui

import org.eclipse.xtext.builder.DerivedResourceMarkers
import org.eclipse.core.resources.IFile
import org.eclipse.core.runtime.CoreException

class MklDerivedResourceMarkers extends DerivedResourceMarkers {
	
	override installMarker(IFile file, String generator, String source) throws CoreException {
		val isDerived = file.isDerived()
		if (!isDerived) {
			return false
		}
		
		super.installMarker(file, generator, source)
	}
	
}